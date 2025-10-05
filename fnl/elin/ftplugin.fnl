(local fennel (require :fennel))

(fn try [func]
  "try to execute function; print fennel.traceback on error"
  (xpcall func (fn [err] (print fennel.traceback err) err)))

(fn undo-ft-plugin [ev typ]
  "helper for b:undo_{ftplugin,indent}_{fnl,lua}"
  (let [undo-fnl (. _G.vim.b ev.buf (.. :undo_ typ :_fnl))
        undo-lua (. _G.vim.b ev.buf (.. :undo_ typ :_lua))]
    (when (or undo-fnl undo-lua)
      (if (= (type undo-fnl) :string) (try #(fennel.eval undo-fnl))
          (= (type undo-fnl) :function) (try #(undo-fnl))
          (= (type undo-lua) :string) (try #(_G.vim.fn.luaeval undo-lua nil))
          (= (type undo-lua) :function) (try #(undo-lua)))
      (tset _G.vim.b ev.buf (.. :undo_ typ :_fnl) nil)
      (tset _G.vim.b ev.buf (.. :undo_ typ :_lua) nil)
      nil)))

(fn do-ft-plugin [ev typ]
  "load {ftplugin,indent}/*.fnl"
  (each [ft (_G.string.gmatch ev.match "[^.]+")]
    (let [paths (-> (_G.string.format "%s/%s.fnl %s/%s_*.fnl" typ ft typ ft)
                    (_G.vim.api.nvim_get_runtime_file true))]
      (each [_ path (ipairs paths)]
        (try #(fennel.dofile path)))))
  nil)

(fn do-syntax [ev]
  "load syntax/*.fnl"
  (each [ft (_G.string.gmatch ev.match "[^.]+")]
    (let [paths (-> (_G.string.format "syntax/%s.fnl" ft)
                    (_G.vim.api.nvim_get_runtime_file true))]
      (each [_ path (ipairs paths)]
      path (try #(fennel.dofile path)))))
  nil)

(fn do-filetype-plugins [ev]
  "filtype plugins: [undo_ftplugin_fnl,] ftplugin, indent, syntax"
  (let [ftp-on (let [on _G.vim.g.did_load_ftplugin] (or (= on 1) (= on true)))
        ind-on (let [on _G.vim.g.did_indent_on] (or (= on 1) (= on true)))
        syn-on (let [on _G.vim.g.syntax_on] (or (= on 1) (= on true)))]
    ;; todo: ? &cpo =~ 'S' => unlet b:did_ftplugin
    (when ftp-on
      (undo-ft-plugin ev :ftplugin)
      (do-ft-plugin ev :ftplugin)
      (when ind-on
        (undo-ft-plugin ev :indent)
        (do-ft-plugin ev :indent)))
    (when syn-on
      (do-syntax ev))
    nil))

{: do-filetype-plugins}
