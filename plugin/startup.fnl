;; mandatory guard (prevents infinite recursive loading during plugin INIT)
(when _G._elin-did-startup (lua :return))
(set _G._elin-did-startup true)

(local fennel (require :fennel))
(local config (vim.fn.stdpath :config))

(set fennel.path (.. config "/fnl/?.fnl;" config "/fnl/?/init.fnl"))
; ; ; ;; ↓ dev only ↓ warning: remove lua/**/*.lua files
; ; ; (set fennel.path
; ; ;      (.. fennel.path ";"
; ; ;          config "/pack/local/start/elin/fnl/?.fnl;"
; ; ;          config :/pack/local/start/elin/fnl/?/init.fnl))
; ; ; ;; ↑ dev only ↑
(fennel.install) ; we need our own package.loader anyway

(fn no-rtp-file [glob]
  "true if {glob} is not in &runtimepath; else false"
  (= (. (vim.api.nvim_get_runtime_file glob false) 1) nil))

(fn all-rtp-files [glob]
  "get all files matching {glob} in &runtimepath"
  (vim.api.nvim_get_runtime_file glob true))

(fn try [func]
  "try to execute function; print fennel.traceback on error"
  (xpcall func (fn [err] (print fennel.traceback err) err)))

;; todo: ? respect -u flag?

;; load init.fnl (if exists) when init.{lua,vim} not found
(when (and (no-rtp-file :init.lua) (no-rtp-file :init.vim))
  (case (vim.api.nvim_get_runtime_file :init.fnl false)
    [file] (do
             (vim.uv.os_setenv :MYVIMRC file)
             (try #(fennel.dofile file)))))

;; plugin INIT (disable with --noplugins)
(when vim.o.loadplugins
  (each [_ path (ipairs (all-rtp-files :plugin/**/*.fnl))]
    (try #(fennel.dofile path))))

;; lsp INIT
(each [_ path (ipairs (all-rtp-files :lsp/*.fnl))]
  (try #(with-open [file (io.open path)]
          (let [config (fennel.eval (file:read :*a))
                name (-> path (: :gsub ".*/" "") (: :gsub "%.fnl$" ""))]
            (vim.lsp.config name config)))))

(fn undo-ft-plugin [ev typ]
  "helper for b:undo_{ftplugin,indent}_{fnl,lua}"
  (let [undo-fnl (. vim.b ev.buf (.. :undo_ typ :_fnl))
        undo-lua (. vim.b ev.buf (.. :undo_ typ :_lua))]
    (when (or undo-fnl undo-lua)
      (if (= (type undo-fnl) :string) (try #(fennel.eval undo-fnl))
          (= (type undo-fnl) :function) (try #(undo-fnl))
          (= (type undo-lua) :string) (try #(vim.fn.luaeval undo-lua nil))
          (= (type undo-lua) :function) (try #(undo-lua)))
      (tset vim.b ev.buf (.. :undo_ typ :_fnl) nil)
      (tset vim.b ev.buf (.. :undo_ typ :_lua) nil))))

(fn do-ft-plugin [ev typ]
  "load {ftplugin,indent}/*.fnl"
  (each [ft (string.gmatch ev.match "[^.]+")]
    (let [paths (-> (string.format "%s/%s.fnl %s/%s_*.fnl" typ ft typ ft)
                    (vim.api.nvim_get_runtime_file true))]
      (each [_ path (ipairs paths)]
        (try #(fennel.dofile path))))))

(fn do-syntax [ev]
  "load syntax/*.fnl"
  (each [ft (string.gmatch ev.match "[^.]+")]
    (let [paths (-> (string.format "syntax/%s.fnl" ft)
                    (vim.api.nvim_get_runtime_file true))]
      (each [_ path (ipairs paths)]
      path (try #(fennel.dofile path))))))

(fn do-filetype-plugins [ev]
  "filtype plugins: [undo_ftplugin_fnl,] ftplugin, indent, syntax"
  (let [ftp-on (let [on vim.g.did_load_ftplugin] (or (= on 1) (= on true)))
        ind-on (let [on vim.g.did_indent_on] (or (= on 1) (= on true)))
        syn-on (let [on vim.g.syntax_on] (or (= on 1) (= on true)))]
    ;; todo: ? &cpo =~ 'S' => unlet b:did_ftplugin
    (when ftp-on
      (undo-ft-plugin ev :ftplugin)
      (do-ft-plugin ev :ftplugin)
      (when ind-on
        (undo-ft-plugin ev :indent)
        (do-ft-plugin ev :indent)))
    (when syn-on
      (do-syntax ev))))

(let [cmd vim.api.nvim_create_user_command]
  (cmd :Fnl
       (fn [ev]
         (let [{: do-eval} (require :elin.commands)]
           (do-eval ev.bang ev.args)
           nil))
       {:nargs "+"
        :bang true
        ;; todo: custom completion (lsp?)
        :desc "fennel.eval {expression} to wherever"})
  (cmd :FnlFiles
       (fn [ev]
         (let [{: do-files} (require :elin.commands)]
           (do-files ev.bang ev.fargs)
           nil))
       {:nargs "+"
        :bang true
        :complete :file
        :desc "fennel.eval files"})
  (cmd :FnlLines
       (fn [ev]
         (let [{: do-lines} (require :elin.commands)]
           (do-lines ev.bang ev.line1 ev.line2 0 ev.args)
           nil))
       {:nargs "*"
        :bang true
        :range "%"
        :desc "fennel.eval range"})
  (cmd :FnlSwiss
        (fn [ev]
          (let [{: do-swiss} (require :elin.commands)]
            (do-swiss ev.bang ev.count ev.line1 ev.line2 0 ev.args)
            nil))
       {:nargs "*"
        :bang true
        :range true
        ; todo: custom fennel completion
        :desc "fennel.eval(<files [range] {expression}) to wherever"}))

(let [aug (vim.api.nvim_create_augroup :elin {})
      au vim.api.nvim_create_autocmd]
  (au :FileType {:group aug
                 :callback (partial do-filetype-plugins)
                 :desc "load fennel files"})
  (au :SourceCmd {:group aug
                  :pattern :*.fnl
                  :callback (fn [ev]
                              (fennel.dofile (vim.fs.normalize ev.file nil))
                              nil)
                  :desc ":source fennel files"}))

nil
