(local version :0.1.1)
(local verbose false)
(local cache-rtp (.. (_G.vim.fn.stdpath :cache) :/elin-rtp))

(fn compile-nvim []
  "backup {cache} and compile entire nvim config to {cache}"
  (when (_G.vim.uv.fs_stat cache-rtp nil)
    (let [{: compile-nvim-config} (require :elin.api)
          elin-rtp (.. (_G.vim.fn.stdpath :cache) :/elin-rtp)]
      (_G.vim.uv.fs_rename elin-rtp (.. elin-rtp :-bak) nil)
      (compile-nvim-config))))

(fn use-elin-rtp []
  "add {cache}/elin-rtp to &runtimepath if not already there"
  (when (not (_G.vim.o.runtimepath:match :/elin-rtp))
    (_G.vim.o.runtimepath:append cache-rtp)))

{: compile-nvim : use-elin-rtp : verbose : cache-rtp : version}
