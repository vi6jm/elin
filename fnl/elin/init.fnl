(local version :v0.0.6)

(local fennel (require :fennel))
(local {: fs_stat : fs_fstat : fs_open : fs_read : fs_write : fs_close}
       _G.vim.uv)

(local get-rtp-file _G.vim.api.nvim_get_runtime_file)
(local loaders (or _G.package.loaders _G.package.searchers))

(var caching-enabled false)
(var cache-dir (.. (_G.vim.fn.stdpath :cache) :/elin/))

(vim.fn.mkdir cache-dir :p)

(fn setup [opts]
  (let [cd (or opts.cache-dir opts.cacheDir)]
    (when (= (type cd) :string)
      (set cache-dir (.. (cd:gsub "/+$" "") "/")))))

(fn get-version [] version)
(fn get-cache-dir [] cache-dir)
(fn caching-enabled? [] caching-enabled)

(let [config (_G.vim.fn.stdpath :config)]
  (set fennel.path (.. config "/fnl/?.fnl;" config "/fnl/?/init.fnl")))
(fennel.install)

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
    (-> path (: :gsub ".*/" "") (: :gsub "%.luac?$")
        (: :gsub "%%(%x%x)" #(string.char (tonumber $1 16))))))

(fn write-cache [path cpath ?opts]
  "cache {path} (fnl) to {cpath} (luac); compile with {?opts}"
  (with-open [fh (_G.io.open path)]
    (case (xpcall #(fennel.compile fh (or ?opts {:filename path :correlate true}))
                  (fn [err] (werr (fennel.traceback err)) err))
      (true code) (let [fh (fs_open cpath :w 438)
                        f (_G.loadstring code)]
                    (fs_write fh (string.dump f true))
                    (fs_close fh)
                    f)
      (_ err) (values nil err))))

(fn dofile-cached [path]
  "fennel dofile with auto-lua caching"
  (let [cpath (get-cache-path path)
        cstat (fs_stat cpath)
        stat (fs_stat path)]
    (case (if (or (= cstat nil) (< cstat.mtime.sec stat.mtime.sec)
                  (< cstat.mtime.nsec stat.mtime.nsec))
              (write-cache path cpath)
              (_G.loadstring (readfile cpath 438)))
      f (f))))

(fn dofile [path]
  "dofile-cached or fennel.dofile (respects caching-enabled)"
  (let [f (if caching-enabled dofile-cached fennel.dofile)]
    (f path)))

(fn loader [mod]
  "fnl loader with auto-luac caching"
  (let [mod (-> mod (: :gsub "^[/.]+" "") (: :gsub "%." "/"))]
    (case (. (get-rtp-file (.. :fnl/ mod :.fnl " fnl/" mod :/init.fnl) false) 1)
      path (let [cpath (get-cache-path path)
                 cstat (fs_stat cpath)
                 stat (fs_stat path)] (if (or (= cstat nil) (< cstat.mtime.sec stat.mtime.sec) (< cstat.mtime.nsec stat.mtime.nsec))
                 (write-cache path cpath)
                 (readfile cpath 438))))))

(fn disable-caching []
  "disable elin loader and dofile caching"
  (tset _G.package (if _G.package.loaders :loaders :searchers)
        (icollect [_ l (ipairs loaders)]
          (when (not= l loader)
            loader)))
  (set caching-enabled false)
  nil)

(fn enable-caching []
  "enable elin loader with auto-luac caching"
  (when caching-enabled
    (disable-caching))
  (_G.table.insert loaders 2 loader)
  (set caching-enabled true)
  nil)

{: setup
 : get-version
 :getVersion get-version
 : enable-caching : disable-caching
 :enableCaching enable-caching :disableCaching disable-caching
 : caching-enabled?
 :isCachingEnabled caching-enabled?
 : dofile
 : get-cache-path : get-uncache-path
 :getCachePath get-cache-path :getUncachePath get-uncache-path
 : get-cache-dir
 :getCacheDir get-cache-dir}
