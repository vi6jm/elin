(fn check []
  (let [fnl-path (. (vim.api.nvim_get_runtime_file :lua/fennel.lua false) 1)
        fnlc-path (. (vim.api.nvim_get_runtime_file :lua/fennel.luac false) 1)
        elin (require :elin)]
    (vim.health.start (.. "elin (" (elin.get-version) ") report"))
    (if (elin.caching-enabled?)
      (vim.health.info (.. "caching enabled (path: " (elin.get-cache-dir) ")"))
      (vim.health.info ("caching not enabled")))
    (if _G.___elin-did-startup___
      (vim.health.ok "elin did startup successfully")
      (vim.health.warn "elin did not startup"))
    (if fnlc-path
      (vim.health.ok (.. "cached fennel.lua detected: " fnlc-path))
      (vim.health.error "no cached fennel.lua detected"))
    (if fnl-path
      (vim.health.ok (.. "fennel.lua detected: " fnl-path))
      (vim.health.error "no fennel.lua detected"))
    (if _G.___elin-did-init-fnl___
      (vim.health.ok "{config}/init.fnl was sourced")
      (if (_G.vim.uv.fs_stat (.. (_G.vim.fn.stdpath :config) :/init.fnl))
        (vim.health.warn "{config}/init.fnl exists but was not successfully sourced")
        (vim.health.info "{config}/init.fnl does not exist")))))
{: check}
