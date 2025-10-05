local version = "0.1.1"
local verbose = false
local cache_rtp = (_G.vim.fn.stdpath("cache") .. "/elin-rtp")
local function compile_nvim()
  if _G.vim.uv.fs_stat(cache_rtp, nil) then
    local _let_1_ = require("elin.api")
    local compile_nvim_config = _let_1_["compile-nvim-config"]
    local elin_rtp = (_G.vim.fn.stdpath("cache") .. "/elin-rtp")
    _G.vim.uv.fs_rename(elin_rtp, (elin_rtp .. "-bak"), nil)
    return compile_nvim_config()
  else
    return nil
  end
end
local function use_elin_rtp()
  if not _G.vim.o.runtimepath:match("/elin-rtp") then
    return _G.vim.o.runtimepath:append(cache_rtp)
  else
    return nil
  end
end
return {["compile-nvim"] = compile_nvim, ["use-elin-rtp"] = use_elin_rtp, verbose = verbose, ["cache-rtp"] = cache_rtp, version = version}
