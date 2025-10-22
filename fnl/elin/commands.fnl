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

(fn werr [msg]
  "write error message using nvim_echo"
  (_G.vim.api.nvim_echo [[msg]] true {:err true :kind :errormsg}))

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
  (case (xpcall #(eval expr {:filename :stdin :error-pinpoint false})
                (fn [err] (werr err) err))
    (true result) (handle-matches bang? matches result)))

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


(fn promptCallback [repl text]
  (coroutine.resume
    repl (.. (text:gsub "\n+$" "") "\n")))

(fn onValues [buf vals]
  (vim.api.nvim_buf_set_lines buf -2 -1 true
                              (if (= (length vals) 0)
                                  [:nil]
                                  (let [lines []]
                                    (each [_ val (ipairs vals)]
                                      (icollect [line (string.gmatch val
                                                                     "[^\n]+")
                                                 &into lines]
                                        line))
                                    lines)))
  nil)

(fn onError [buf err]
  (vim.api.nvim_buf_set_lines buf -2 -1 true (vim.split err "\n"))
  nil)

(fn repl [bang? smods]
  (local buf (vim.api.nvim_create_buf false true))
  (local fennel (require :fennel))
  (vim.api.nvim_buf_set_lines buf -2 -1 true
                              [(.. "Welcome to Fennel " fennel.version " on "
                                   (if _G.jit _G.jit.version
                                       (.. "PUC " _VERSION))
                                   " in Neovim " (tostring (vim.version)) "!")])
  (vim.api.nvim_set_option_value :bufhidden :wipe {: buf})
  (vim.api.nvim_set_option_value :buftype :prompt {: buf})
  (vim.api.nvim_buf_set_name buf "Fennel REPL")
  ;; todo incr #
  (vim.fn.prompt_setprompt buf ">> ")
  (local repl (coroutine.create (partial fennel.repl)))
  (vim.fn.prompt_setcallback buf (partial promptCallback repl))
  (coroutine.resume repl {:error-pinpoint false
                          :readChunk coroutine.yield
                          :onValues (partial onValues buf)
                          :onError #(onError buf $2)})
  (if bang?
      (let [w (vim.api.nvim_get_option_value :columns {})
            h (vim.api.nvim_get_option_value :lines {})
            ww (math.floor (* w 0.8))
            wh (math.floor (* h 0.8))]
        (vim.api.nvim_open_win buf true
                               {:relative :editor
                                :width ww
                                :height wh
                                :row (math.floor (/ (- h wh) 2))
                                :col (math.floor (/ (- w ww) 2))
                                :style :minimal
                                :border :rounded}))
      (vim.cmd.sbuffer {:args [buf] :mods smods}))
  (vim.keymap.set :i :<C-d>
                  "prompt_getinput(bufnr()) == '' ? '<C-Bslash><C-n>:q!<CR>' : '<C-d>'"
                  {:buffer buf :expr true})
  (vim.keymap.set :i :<C-l> :<C-Bslash><C-n>zti {:buffer buf})
  (vim.cmd.startinsert)
  nil)

{: do-eval : do-files : do-lines : do-swiss : repl}
