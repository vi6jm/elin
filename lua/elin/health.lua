local function check()
  local fnl_path = vim.api.nvim_get_runtime_file("lua/fennel.lua", false)[1]
  local fnlc_path = vim.api.nvim_get_runtime_file("lua/fennel.luac", false)[1]
  local elin = require("elin")
  vim.health.start(("elin (" .. elin["get-version"]() .. ") report"))
  if elin["caching-enabled?"]() then
    vim.health.info(("caching enabled (path: " .. elin["get-cache-dir"]() .. ")"))
  else
    vim.health.info(("caching not enabled")())
  end
  if _G["___elin-did-startup___"] then
    vim.health.ok("elin did startup successfully")
  else
    vim.health.warn("elin did not startup")
  end
  if fnlc_path then
    vim.health.ok(("cached fennel.lua detected: " .. fnlc_path))
  else
    vim.health.error("no cached fennel.lua detected")
  end
  if fnl_path then
    vim.health.ok(("fennel.lua detected: " .. fnl_path))
  else
    vim.health.error("no fennel.lua detected")
  end
  if _G["___elin-did-init-fnl___"] then
    return vim.health.ok("{config}/init.fnl was sourced")
  else
    if _G.vim.uv.fs_stat((_G.vim.fn.stdpath("config") .. "/init.fnl")) then
      return vim.health.warn("{config}/init.fnl exists but was not successfully sourced")
    else
      return vim.health.info("{config}/init.fnl does not exist")
    end
  end
end
return {check = check}
