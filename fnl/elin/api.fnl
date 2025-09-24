(local fennel (require :fennel))
(local uv (or vim.loop vim.uv))
(local elin (require :elin))

(local _config (.. (vim.fn.stdpath :config) :/))
(local _config-len (length _config))
(local _o755 493)
(local _fnl-files "{fnl,plugin,ftplugin,syntax,colors,compile,lsp}/**/*.fnl")

(fn _make-all-dirs [file mode]
  (local dirs {})
  (var dir (vim.fs.dirname file))
  (while (= (uv.fs_stat dir) nil)
    (table.insert dirs 1 dir)
    (set dir (vim.fs.dirname dir)))
  (each [_ dir (ipairs dirs)]
    (uv.fs_mkdir dir mode)))

(fn _fnl-to-lua-fname [fnl-fname]
  (.. elin.cache-rtp (-> (fnl-fname:sub _config-len)
                     (: :gsub :^fnl/ :lua/)
                     (: :gsub :%.fnl$ :.lua))))

(fn _compile-nvim [fnl-fname opts]
  (if (= (fnl-fname:sub 1 _config-len) _config)
    (with-open [fnl-fh (io.open fnl-fname)]
      (local lua-fname (_fnl-to-lua-fname fnl-fname))
      (set opts.filename fnl-fname)
      (_make-all-dirs lua-fname _o755)
      (case (xpcall #(fennel.compile fnl-fh opts) #$)
        (true lua-out) (with-open [lua-fh (io.open lua-fname :w)]
                         (lua-fh:write lua-out)
                         (lua-fh:write "\n")
                         [true nil fnl-fname lua-fname])
        (_    err    ) (do (when elin.verbose
                             (let [qname (string.format :%q fnl-fname)]
                               (print (.. "error compiling " qname ": " err))))
                         [false err fnl-fname nil])))
    (do
      (when elin.verbose
        (print (.. "error before compiling: file not `config` dir: " fnl-fname)))
      [false (.. "file not in nvim `config` dir: " fnl-fname) fnl-fname nil])))

(fn _gather-opts [opts]
  (let [opts (or opts {})]
    (when (= opts.allowGlobals true)
        (set opts.allowGlobals (icollect [g _ (pairs _G)] g)))
    opts))


(fn compile-nvim-config [opts]
  (icollect [_ fnl-fname (ipairs (vim.api.nvim_get_runtime_file _fnl-files true))]
    (_compile-nvim fnl-fname (_gather-opts opts))))

(fn compile-nvim-file [fnl-fname opts]
    (_compile-nvim fnl-fname (_gather-opts opts)))

{: compile-nvim-config :compileNvimConfig compile-nvim-config
 : compile-nvim-file   :compileNvimFile   compile-nvim-file}
