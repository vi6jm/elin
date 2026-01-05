
(var ignore-dirs [(vim.fn.stdpath :config)])
(var markers [:.git/ :flsproject.fnl :init.fnl])

(fn set-ignore-dirs [ignores]
  "Disallow fnl2lua in projects"
  (case (type ignores)
    (where t (or (= t :nil) (= t :table)))
    (set ignore-dirs ignores)
    _ (print "Error: set-ignore-dirs expected `nil` or a table"))
  nil)

(fn add-ignore-dir [dir]
  "Add dir to project ignores"
  (when (not= (type ignore-dirs) :table)
    (set ignore-dirs []))
  (table.insert ignore-dirs dir))

(fn _list-index [list pat]
  "Find the index of pat in list, returning nil if not found"
  (var res nil)
  (each [idx val (ipairs list) :until res]
    (when (= val pat)
      (set res idx)))
  res)

(fn remove-ignore-dir [dir]
  "Remove dir from project ignores"
  (if (= (type ignore-dirs) :table)
    (case (_list-index ignore-dirs dir)
      idx (table.remove ignore-dirs idx))
    (do (set ignore-dirs nil) nil)))

(fn get-ignore-dirs []
  "Get the list of ignored project directories"
  (icollect [_ v (ipairs ignore-dirs)] v))

(fn _fs-dir-has-file [source file]
  "Check if a file (dir if ends with '/') exists in the source dir"
  (let [path (.. source "/" file)
        is-dir? (vim.endswith file "/")]
    (case (vim.uv.fs_stat path)
      nil false
      stat (if is-dir?
               (= stat.type :directory)
               (and (or (= stat.type :file) (= stat.type :link))
                    (not= nil (vim.uv.fs_access path :R)))))))

(fn _fs-last-root [source]
  "Find the project root directory by searching for markers in parent directories"
  (var res nil)
  (each [dir (vim.fs.parents source) :until res]
    (each [_ marker (ipairs markers) :until res]
      (when (_fs-dir-has-file dir marker)
        (set res dir))))
  res)

(fn werr [msg]
  "write error message using nvim_echo"
  (_G.vim.api.nvim_echo [[msg]] true {:err true :kind :errormsg}))

(fn compile [file] ; Q: should there be another 'strategy' or more?
  "Compile the fennel file to its respective lua output"
  (let [filename (vim.fs.abspath file)
        dir (vim.fs.dirname filename)]
    (case (_fs-last-root dir)
      root (when (not (vim.list_contains ignore-dirs root))
             (let [rel-file (filename:sub (+ 2 (length root)))
                   rel-file (rel-file:gsub :^fnl/ "")
                   rel-file (rel-file:gsub "%.fnl$" "")
                   rel-file (.. rel-file :.lua)
                   fout-name (.. root :/lua/ rel-file)
                   {: compile : traceback} (require :fennel)]
               (vim.fn.mkdir (vim.fs.dirname fout-name) :p)
               (with-open [fin (io.open filename) fout (io.open fout-name :w)]
                 (case (xpcall #(compile fin {: filename})
                               (fn [err] (werr (traceback err)) err))
                   (true code) (fout:write code)
                   (_ err) (values nil err)))))))
  nil)

(fn enable [callback?]
  "Enable the fnl2lua via ~ BufWritePost *.fnl Fnl (compile <q-amatch>)"
  (let [group (_G.vim.api.nvim_create_augroup :elin_fnl2lua {})
        callback (or callback? compile)]
    (set _G.___elin-fnl2lua-auid___ group)
    (_G.vim.api.nvim_create_autocmd :BufWritePost
                                    {:pattern :*.fnl
                                     : group
                                     :callback #(callback (vim.fs.normalize $1.file))})))

(fn disable []
  "Disable the fnl2lua feature by clearing the autocmd group."
  (when _G.___elin-fnl2lua-auid___
    _G.vim.api.nvim_clear_autocmd {:group _G.___elin-fnl2lua-auid___})
  (set _G.___elin-fnl2lua-auid___ nil))

(fn set-project-markers [m]
  "Set project markers to help determine the root of a project directory"
  (when (= (type m) :table)
    (set markers m)))

{: enable
 : disable
 : set-ignore-dirs
 : add-ignore-dir
 : remove-ignore-dir
 : get-ignore-dirs
 : set-project-markers
 : compile}
