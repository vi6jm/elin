
;; todo?: respect $NVIM_APPNAME

(local elin (require :elin))
(elin.do-startup)

(let [cmd _G.vim.api.nvim_create_user_command]
  (cmd :Fnl #(let [{: do-eval} (require :elin.commands)]
               (do-eval $1.bang $1.args)
               nil)
       {:nargs "+"
        :bang true
        ;; todo: custom completion (lsp?)
        :desc "fennel.eval {expression} to wherever"})
  (cmd :FnlFiles #(let [{: do-files} (require :elin.commands)]
                     (do-files $1.bang $1.fargs)
                     nil)
       {:nargs "+" :bang true :complete :file :desc "fennel.eval files"})
  (cmd :FnlLines #(let [{: do-lines} (require :elin.commands)]
                     (do-lines $1.bang $1.line1 $1.line2 0 $1.args)
                     nil)
       {:nargs "*" :bang true :range "%" :desc "fennel.eval range"})
  (cmd :FnlSwiss #(let [{: do-swiss} (require :elin.commands)]
                    (do-swiss $1.bang $1.count $1.line1 $1.line2 0 $1.args)
                    nil)
       {:nargs "*"
        :bang true
        :range true
        ; todo: custom fennel completion
        :desc "fennel.eval (<files [range] {expression}) to wherever"})
  (cmd :FnlRepl #(let [{: repl} (require :elin.commands)]
                    (repl $1.bang $1.smods)
                    nil)
       {:nargs 0 :bang true :bar true :desc "fennel repl"}))

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
