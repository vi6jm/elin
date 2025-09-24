(fn fnl [expr reg]
  (let [{: eval : view} (require :fennel)
        result (eval expr)]
    (case reg
      "" (print (view result))
      reg (vim.fn.setreg reg result))))

(fn dofile [file reg]
  (let [{: dofile : view} (require :fennel)
        result (dofile (vim.fs.normalize file nil))]
    (case reg
      "" (print (view result))
      reg (vim.fn.setreg reg result))))

(fn dolines [line1 line2 buf reg]
  (let [{: eval : view} (require :fennel)
        l1 (- line1 1)
        l2 line2
        lines (-> (vim.api.nvim_buf_get_lines buf l1 l2 true)
                  (table.concat "\n"))
        result (eval lines)]
    (case reg
      "" (print (view result))
      reg (vim.fn.setreg reg result))))

{: fnl : dofile : dolines}
