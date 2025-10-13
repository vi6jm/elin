;; source guard; keep first
(when _G._elin-did-startup (lua :return))
(set _G._elin-did-startup true)

;; todo?: respect $NVIM_APPNAME

(local elin (require :elin))
(elin.do-startup)

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
                              (do-filetype-plugins $1))
                 :desc "load fennel files"})
  (au :SourceCmd {:group aug
                  :pattern :*.fnl
                  :callback (fn [ev]
                              (elin.dofile (_G.vim.fs.normalize ev.file nil))
                              nil)
                  :desc ":source fennel files"}))

nil
