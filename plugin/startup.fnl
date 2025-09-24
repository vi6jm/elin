;; mandatory guard (prevents infinite recursive loading during plugin INIT)
(when _G._elin-did-startup (lua :return))
(set _G._elin-did-startup true)

(local fennel (require :fennel))
(local config (vim.fn.stdpath :config))

(set fennel.path (.. config "/fnl/?.fnl;" config "/fnl/?/init.fnl"))
(fennel.install)

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
    (try #(fennel.dofile path)))
  (each [_ path (ipairs (all-rtp-files :after/plugin/**/*.fnl))]
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
      (tset vim.b ev.buf (:undo_ typ :_fnl) nil)
      (tset vim.b ev.buf (:undo_ typ :_lua) nil))))

;; todo: for ftplugin/indent/syntax, split &ft on '.'
;; todo: this gets loaded multiple times. find how to prevent (time + state)
;; ftplugin or indent filetype plugin
(fn do-ft-plugin [ev typ]
  "load {,after}/{ftplugin,indent}/*.fnl when b:did_{ftplugin,indent} = 0"
  (let [glob (-> (.. typ :/ ev.match :.fnl)
                 (vim.api.nvim_get_runtime_file false)
                 (. 1))
        aglob (-> (.. :after/ typ :/ ev.match :.fnl)
                  (vim.api.nvim_get_runtime_file false)
                  (. 1))]
    (case glob
      path (try #(fennel.dofile path)))
    (case aglob
      path (try #(fennel.dofile path)))))

;; syntax "filetype plugin"
(fn do-syntax [ev]
  "load {,after}/syntax/*.fnl"
  (let [syng (-> (.. :syntax/ ev.match :.fnl)
                 (vim.api.nvim_get_runtime_file false)
                 (. 1))
        asyng (-> (.. :after/syntax ev.match :.fnl)
                  (vim.api.nvim_get_runtime_file false)
                  (. 1))]
    (case syng
      path (try #(fennel.dofile path)))
    (case asyng
      path (try #(fennel.dofile path)))))

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
  ; todo: :Fnl*Put ? or :Fnl => reg good enough?
  (cmd :Fnl #(let [{: fnl} (require :elin.commands)]
               (fnl $1.args $1.reg))
       {:nargs 1
        :bar true
        ; todo: custom fennel completion (fennel-ls??)
        :register true
        :desc "fennel.eval {expression} to cmdline or register"})
  (cmd :FnlDofile #(let [{: dofile} (require :elin.commands)]
                     (dofile $1.args ""))
       {:nargs 1
        :complete :file
        :desc ":fennel.dofile {file} to cmdline or register"})
  (cmd :FnlDofileReg #(let [{: dofile} (require :elin.commands)]
                        (dofile $1.args $1.reg))
       {:nargs 1
        :complete :file
        :register true
        :desc ":fennel.dofile {file} to cmdline or register"})
  (cmd :FnlDolines #(let [{: dolines} (require :elin.commands)]
                      (dolines $1.line1 $1.line2 0 $1.reg))
       {:nargs 0
        :bar true
        :range true
        :register true
        :desc "fennel.eval [range] to cmdline or register"}))

(let [aug (vim.api.nvim_create_augroup :elin {})
      au vim.api.nvim_create_autocmd]
  (au :FileType {:group aug
                 :callback (partial do-filetype-plugins)
                 :desc "load fennel files"})
  (au :SourceCmd {:group aug
                  :pattern :*.fnl
                  :callback #(fennel.dofile (vim.fs.normalize $1.file nil))
                  :desc ":source fennel files"}))

nil
