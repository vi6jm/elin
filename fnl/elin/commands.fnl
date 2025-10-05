(local {: P : R : S : C : Cs : Ct} _G.vim.lpeg)

(local ^0 #(^ $1 0))
(local ^1 #(^ $1 1))
(local ^-1 #(^ $1 -1))
(local ^-2 #(^ $1 -2))

(local \s (S " \t")) ; /\s*/
(local \s* (^0 \s)) ; /\s+/
(local gt (P ">")) ; />/
(local ** (C (^0 (P 1)))) ; /(.*)/

(local file (let [fname (^1 (- (+ (* (P "\\") 1) (P 1)) (S "<>()@ \t")))
                  file-sub (fn [f]
                             (f:gsub "\\(.)"
                                     #(case ($1:match "[ \\]")
                                        s s
                                        ?s (.. "\\" ?s))))]
              (* \s* (Cs (/ fname file-sub))))) ; ~ /[^<>()@ \t]+/

(local cmd* ;; avert your eyes
  (let [; /(>)\s*({file})\s*/
        to-file (* (C gt) (/ (^-1 gt) #(= $1 ">")) (- gt) file \s*)
        ; /[A-z]/
        reg (+ (R :az :AZ) (S "\"*+_"))
        ; /(>{0,2})>\@!\s*/
        C-gt (* (/ (^-2 gt) #(= $1 ">>")) (- gt) \s*)
        ; /({reg})({C-gt})/
        to-reg (* (C "@") (C reg) C-gt)
        ; /(>?)>\@!\s*/
        C-gt (* (/ (^-2 gt) #(= $1 ">")) (- gt) \s*)
        ; /[A-z_]/
        vim-var (+ (R :az :AZ) (S "_"))
        ; /[A-z_][A-z_0-9]*/
        vim-var (* vim-var (^0 (+ vim-var (R :09))))
        ; /(=>)\s*({vim-var})\s*/
        to-vim-var (* (C "=>") C-gt (C vim-var) \s*)
        ; /[A-z_<>!?|^*+-=%\\]/
        fnl-var (+ (R :az :AZ) (S "_<>!?|^*/-+=%\\"))
        ; /{fnl-var}[A-z_<>!?|^*+-=%\\0-9]*//
        fnl-var (* fnl-var (^0 (+ fnl-var (R :09))))
        ; /(->)\s*({fnl-var})\s*/
        to-fnl-var (* (C "->") C-gt (C fnl-var) \s*)
        ; /(==)=@\!\s*/
        to-put (* (C "==") (- (P "=")) \s*)
        to-all (+ to-file to-reg to-vim-var to-fnl-var to-put)]
    (+ (* (Ct (* \s* to-all)) **) (* (Ct "") **)))) ; ~ /({to-all}{**}|{**})/

(fn view-result [bang? result]
  (let [{: view} (require :fennel)
        result (view result)]
    (if bang? result (.. "=> " (result:gsub "\n" "\n   ")))))

(fn handle-matches [bang? matches result]
  (case matches
    ["@" "_"] nil
    ["@" reg a?] (_G.vim.fn.setreg reg result (if a? :a nil))
    ["=>" a? name] (let [result (.. (if a? (. _G.vim.g name) "") result)]
                          (tset _G.vim.g name result))
    ["->" a? name] (tset _G name (.. (if a? (. _G name) "") result))
    ["=="] (let [line (if (and (= (_G.vim.api.nvim_buf_line_count 0) 1)
                               (= (. (_G.vim.api.nvim_buf_get_lines 0 0 1 true) 1) ""))
                        0
                        (+ (. (_G.vim.api.nvim_win_get_cursor 0) 1) 1))
                 line (_G.math.min line (_G.vim.api.nvim_buf_line_count 0))
                 result (if bang? (.. "; " (result:gsub "\n" "\n; ")) result)]
             (_G.vim.api.nvim_buf_set_lines 0 line line true result))
    _ (print (view-result bang? result)))
  nil)
  
;; todo remove eval and let each fn below handle it's a pain but it's required
(fn handle [bang? matches expr]
  (local {: eval} (require :fennel))
  (case (pcall #(eval expr {:filename :stdin}))
    (true result) (handle-matches bang? matches result)
    (_ err) (_G.vim.api.nvim_err_writeln
              (#$1 (err:gsub "\n.*" (.. "\nconcatenated input:\n  "
                                        (expr:gsub "\n" "\n  ")))))))

(fn do-eval [bang? cmd]
  ; "Eval fennel expression; eg :Fnl (print :hello :world)"
  (handle bang? (cmd*:match cmd)))

(fn do-files [bang? files]
  "Eval files as concatenated fennel expression; eg :FnlFiles foo.fnl bar.lua"
  (let [expr (-> (icollect [_ fname (ipairs files)]
                   (let [fname (_G.vim.fs.normalize fname)]
                    (with-open [file (io.open fname :r)]
                      (.. ";; " fname "\n" (file:read "*a")))))
                 (_G.table.concat "\n"))]
  (handle bang? (cmd*:match expr)))) ;; todo: eval each with file=file + result

(fn do-lines [bang? line1 line2 ?buf cmd]
  "Eval selected range as fennel expression; eg :'{,'}FnlRange"
  (let [line1 (- line1 1)
        buf (or ?buf 0)
        lines (-> (_G.vim.api.nvim_buf_get_lines buf line1 line2 true)
                  (_G.table.concat "\n"))
        (matches _) (cmd*:match cmd)]
    (handle bang? matches lines)))

(fn do-swiss [bang? count l1 l2 ?buf cmd]
  "Swiss army knife: all above merged; eg :.FnlRange <~/foo.fnl (print :hi)"
  (let [files* (* (Ct (^ (* \s* (P "<") \s* file) 0)) \s* **)
        (files cmd) (files*:match cmd)
        (matches expr) (cmd*:match cmd)
        (files2 expr) (files*:match expr)
        files (icollect [_ file (ipairs files2) &into files] file)
        cat (-> (icollect [_ fname (ipairs files)]
                  (let [fname (_G.vim.fs.normalize fname)]
                    (with-open [file (io.open fname :r)]
                      (.. ";; " fname "\n" (file:read :*a)))))
                (_G.table.concat "\n"))
        buf (or ?buf 0)
        lines (if (<= count 0) ""
                (-> (_G.vim.api.nvim_buf_get_lines buf (- l1 1) l2 true)
                    (_G.table.concat "\n")))
        expr (.. ";; range\n" lines "\n" cat "\n\n;; stdin\n" expr)]
  (handle bang? matches expr))) ;; todo: eval each with file=file if relevant + result

{: do-eval : do-files : do-lines : do-swiss}
