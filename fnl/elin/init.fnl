(local version :v0.0.8)

(local {: fs_stat : fs_fstat : fs_open : fs_read : fs_write : fs_close}
       _G.vim.uv)

(local get-rtp-file _G.vim.api.nvim_get_runtime_file)
(local loaders (or _G.package.loaders _G.package.searchers))

(var caching-enabled false)
(var cache-dir (.. (_G.vim.fn.stdpath :cache) :/elin/))


(fn get-version [] version)
(fn get-cache-dir [] cache-dir)
(fn caching-enabled? [] caching-enabled)

(fn werr [msg]
  "write error message using nvim_echo"
  (_G.vim.api.nvim_echo [[msg]] true {:err true :kind :errormsg}))

(fn readfile [path mode]
  (let [fh (fs_open path :r mode)]
    (when fh
      (let [size (. (assert (fs_fstat fh)) :size)
            data (fs_read fh size 0)]
        (fs_close fh)
        data))))

(fn get-cache-path [path]
  "get cached path for any path"
  (let [cpath (path:gsub "%A" #(string.format "%%%x" (string.byte $1)))]
    (.. cache-dir cpath :.luac)))

(fn get-uncache-path [cpath]
  "get original file name from cached path"
  (let [path (cpath:gsub "%.luac?$" "")]
    (-> path (: :gsub ".*/" "") (: :gsub "%.luac?$" "")
        (: :gsub "%%(%x%x)" #(string.char (tonumber $1 16))))))

(fn write-cache [path cpath ?opts]
  "cache {path} (fnl) to {cpath} (luac); compile with {?opts}"
  (with-open [fh (_G.io.open path)]
    (let [{: compile : traceback} (require :fennel)]
      (case (xpcall #(compile fh (or ?opts {:filename path :correlate true}))
                    (fn [err] (werr (traceback err)) err))
        (true code) (let [fh (fs_open cpath :w 438)
                          f (_G.loadstring code)]
                      (fs_write fh (string.dump f true))
                      (fs_close fh)
                      f)
        (_ err) (values nil err)))))

(fn dofile-cached [path ?opts]
  "fennel dofile with auto-lua caching"
  (let [cpath (get-cache-path path)
        cstat (fs_stat cpath)
        stat (fs_stat path)]
    (case (if (or (= cstat nil) (< cstat.mtime.sec stat.mtime.sec)
                  (< cstat.mtime.nsec stat.mtime.nsec))
              (write-cache path cpath ?opts)
              (_G.loadstring (readfile cpath 438)))
      f (f))))

(fn dofile [path ?opts]
  "dofile-cached or fennel.dofile (respects caching-enabled)"
  (let [f (if caching-enabled dofile-cached (. (require :fennel) :dofile))]
    (f path ?opts)))

(fn loader [mod]
  "fnl loader with auto-luac caching"
  (let [mod (-> mod (: :gsub "^[/.]+" "") (: :gsub "%." "/"))]
    (case (. (get-rtp-file (.. :fnl/ mod :.fnl " fnl/" mod :/init.fnl) false) 1)
      path (let [cpath (get-cache-path path)
                 cstat (fs_stat cpath)
                 stat (fs_stat path)]
             (if (or (= cstat nil) (< cstat.mtime.sec stat.mtime.sec) (< cstat.mtime.nsec stat.mtime.nsec))
                 (write-cache path cpath)
                 (readfile cpath 438))))))

(fn disable-caching []
  "disable elin loader and dofile caching"
  (set _G.package.loaders
        (icollect [_ l (ipairs loaders)]
          (when (not= l loader)
            loader)))
  (set caching-enabled false)
  nil)

(fn enable-caching []
  "enable elin loader with auto-luac caching"
  (when caching-enabled
    (disable-caching))
  (_G.table.insert _G.package.loaders 2 loader)
  (set caching-enabled true)
  nil)

(fn try [func]
  "try to execute function; print fennel.traceback on error"
  (local {: traceback} (require :fennel))
  (xpcall func (fn [err] (print traceback err) err)))

(fn setup [opts]
  (let [ec (or opts.enable-caching opts.enableCaching)
        f (if ec enable-caching disable-caching)]
    (f))
  (let [cd (or opts.cache-dir opts.cacheDir)]
    (when (= (type cd) :string)
      (set cache-dir (.. (cd:gsub "/+$" "") "/")))))

(fn do-startup [?opts]
  (local did-startup _G.___elin-did-startup___)
  (when (= did-startup nil)
    ;; guard sensitive setup that should only be loaded once
    (set _G.___elin-did-startup___ true)
    ;; preload fennel.luac (5x perf increase, user consent?)
    (set _G.package.loaded.fennel
         (let [{: fs_open : fs_fstat : fs_read : fs_close : fs_write} _G.vim.uv]
           (case (. (_G.vim.api.nvim_get_runtime_file :lua/fennel.luac false) 1)
             path (let [fh (fs_open path :r 438)
                        size (. (assert (fs_fstat fh)) :size)
                        data (fs_read fh size 0)]
                    (fs_close fh)
                    (case (_G.loadstring data)
                      f (f)))
             _ (case (. (_G.vim.api.nvim_get_runtime_file :lua/fennel.lua false) 1)
                 path (let [cpath (.. path :c)
                            fh (fs_open cpath :w 438)
                            f (loadfile path)]
                        (fs_write fh (_G.string.dump f true))
                        (fs_close fh)
                        (f))
                 _ (do
                     (print "Fatal: unable to find fennel.lua module")
                     nil))))))
  (let [fennel (require :fennel)
        opts (or ?opts {})
        config (_G.vim.fn.stdpath :config)]
    (when (or (= did-startup nil) opts.force)
      (vim.fn.mkdir cache-dir :p)
      (set fennel.path (.. config "/fnl/?.fnl;" config :/fnl/?/init.fnl))
      (fennel.install)
      ;; try load init.fnl when init.{lua,vim} not found or opts.load-init-fnl
      (when (or opts.load-init-fnl opts.loadInitFnl
                (and (= (fs_stat (.. config :/init.lua)) nil)
                     (= (fs_stat (.. config :/init.vim)) nil)))
        (local init-path (.. config :/init.fnl))
        (when (fs_stat init-path)
          (_G.vim.uv.os_setenv :MYVIMRC init-path)
          (try (fn []
                 (dofile init-path)
                 (set _G.___elin-did-init-fnl___ true)))))
      (let [get-rtp-file _G.vim.api.nvim_get_runtime_file]
        ;; plugin INIT
        (each [_ path (ipairs (get-rtp-file :plugin/**/*.fnl true))]
          (try #(dofile path)))
        ;; lsp INIT
        (each [_ path (ipairs (get-rtp-file :lsp/*.fnl true))]
          (try #(with-open [file (_G.io.open path)]
                  (let [config (fennel.eval (file:read :*a))
                        name (-> path (: :gsub ".*/" "") (: :gsub "%.fnl$" ""))]
                    (_G.vim.lsp.config name config)))))))))

{: setup
 : do-startup
 :doStartup do-startup
 : dofile
 : get-version
 :getVersion get-version
 : enable-caching : disable-caching
 :enableCaching enable-caching :disableCaching disable-caching
 : caching-enabled?
 :isCachingEnabled caching-enabled?
 : get-cache-path : get-uncache-path
 :getCachePath get-cache-path :getUncachePath get-uncache-path
 : get-cache-dir
 :getCacheDir get-cache-dir}
