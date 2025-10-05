;; mandatory guard (prevents infinite recursive loading during plugin INIT)
(when _G._elin-did-startup (lua :return))
(set _G._elin-did-startup true)

(local fennel (require :fennel))
(local config (_G.vim.fn.stdpath :config))

(set fennel.path (.. config "/fnl/?.fnl;" config "/fnl/?/init.fnl"))
; ; ; ;; ↓ dev only ↓ warning: remove lua/**/*.lua files
; ; ; (set fennel.path
; ; ;      (.. fennel.path ";"
; ; ;          config "/pack/local/start/elin/fnl/?.fnl;"
; ; ;          config :/pack/local/start/elin/fnl/?/init.fnl))
; ; ; ;; ↑ dev only ↑
(fennel.install {:correlate true}) ; we need our own package.loader anyway

(fn no-rtp-file [glob]
  "true if {glob} is not in &runtimepath; else false"
  (= (. (_G.vim.api.nvim_get_runtime_file glob false) 1) nil))

(fn all-rtp-files [glob]
  "get all files matching {glob} in &runtimepath"
  (_G.vim.api.nvim_get_runtime_file glob true))

(fn try [func]
  "try to execute function; print fennel.traceback on error"
  (xpcall func (fn [err] (print fennel.traceback err) err)))

;; todo: ? respect -u flag?

;; load init.fnl (if exists) when init.{lua,vim} not found
(when (and (no-rtp-file :init.lua) (no-rtp-file :init.vim))
  (case (_G.vim.api.nvim_get_runtime_file :init.fnl false)
    [file] (do
             (_G.vim.uv.os_setenv :MYVIMRC file)
             (try #(fennel.dofile file)))))

;; plugin INIT (disable with --noplugins)
(when _G.vim.o.loadplugins
  (each [_ path (ipairs (all-rtp-files :plugin/**/*.fnl))]
    (try #(fennel.dofile path))))

;; lsp INIT
(each [_ path (ipairs (all-rtp-files :lsp/*.fnl))]
  (try #(with-open [file (_G.io.open path)]
          (let [config (fennel.eval (file:read :*a))
                name (-> path (: :gsub ".*/" "") (: :gsub "%.fnl$" ""))]
            (_G.vim.lsp.config name config)))))


(let [cmd _G.vim.api.nvim_create_user_command]
  (cmd :Fnl (fn [ev]
              (let [{: do-eval} (require :elin.commands)]
                (do-eval ev.bang ev.args)
                nil))
       {:nargs "+"
        :bang true
        ;; todo: custom completion (lsp?)
        :desc "fennel.eval {expression} to wherever"})
  (cmd :FnlFiles (fn [ev]
                   (let [{: do-files} (require :elin.commands)]
                     (do-files ev.bang ev.fargs)
                     nil))
       {:nargs "+" :bang true :complete :file :desc "fennel.eval files"})
  (cmd :FnlLines (fn [ev]
                   (let [{: do-lines} (require :elin.commands)]
                     (do-lines ev.bang ev.line1 ev.line2 0 ev.args)
                     nil))
       {:nargs "*" :bang true :range "%" :desc "fennel.eval range"})
  (cmd :FnlSwiss (fn [ev]
                   (let [{: do-swiss} (require :elin.commands)]
                     (do-swiss ev.bang ev.count ev.line1 ev.line2 0 ev.args)
                     nil))
       {:nargs "*"
        :bang true
        :range true
        ; todo: custom fennel completion
        :desc "fennel.eval(<files [range] {expression}) to wherever"}))

(let [aug (_G.vim.api.nvim_create_augroup :elin {})
      au _G.vim.api.nvim_create_autocmd]
  (au :FileType {:group aug
                 :callback #(let [{: do-filetype-plugins} (require :elin.ftplugin)]
                              (do-filetype-plugins))
                 :desc "load fennel files"})
  (au :SourceCmd {:group aug
                  :pattern :*.fnl
                  :callback (fn [ev]
                              (fennel.dofile (_G.vim.fs.normalize ev.file nil))
                              nil)
                  :desc ":source fennel files"}))

nil
