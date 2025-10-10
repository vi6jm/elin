if _G["_elin-did-startup"] then
  return
else
end
_G["_elin-did-startup"] = true
local function _2_()
  local fs_open = _G.vim.uv["fs_open"]
  local fs_fstat = _G.vim.uv["fs_fstat"]
  local fs_read = _G.vim.uv["fs_read"]
  local fs_close = _G.vim.uv["fs_close"]
  local _3_ = _G.vim.api.nvim_get_runtime_file("lua/fennel.luac", false)[1]
  if (nil ~= _3_) then
    local path = _3_
    local fh = fs_open(path, "r", 438)
    local size = assert(fs_fstat(fh)).size
    local data = fs_read(fh, size, 0)
    fs_close(fh)
    local _4_ = _G.loadstring(data)
    if (nil ~= _4_) then
      local f = _4_
      return f()
    else
      return nil
    end
  else
    return nil
  end
end
_G.package.preload.fennel = _2_
local elin = require("elin")
local fennel = require("fennel")
local function no_rtp_file(glob)
  return (_G.vim.api.nvim_get_runtime_file(glob, false)[1] == nil)
end
local function all_rtp_files(glob)
  return _G.vim.api.nvim_get_runtime_file(glob, true)
end
local function try(func)
  local function _7_(err)
    print(fennel.traceback, err)
    return err
  end
  return xpcall(func, _7_)
end
if (no_rtp_file("init.lua") and no_rtp_file("init.vim")) then
  local _8_ = _G.vim.api.nvim_get_runtime_file("init.fnl", false)
  if ((_G.type(_8_) == "table") and (nil ~= _8_[1])) then
    local file = _8_[1]
    _G.vim.uv.os_setenv("MYVIMRC", file)
    local function _9_()
      return elin.dofile(file)
    end
    try(_9_)
  else
  end
else
end
for _, path in ipairs(all_rtp_files("plugin/**/*.fnl")) do
  local function _12_()
    return elin.dofile(path)
  end
  try(_12_)
end
for _, path in ipairs(all_rtp_files("lsp/*.fnl")) do
  local function _13_()
    local file = _G.io.open(path)
    local function close_handlers_12_(ok_13_, ...)
      file:close()
      if ok_13_ then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _15_()
      local config = fennel.eval(file:read("*a"))
      local name = path:gsub(".*/", ""):gsub("%.fnl$", "")
      return _G.vim.lsp.config(name, config)
    end
    local _17_
    do
      local t_16_ = _G
      if (nil ~= t_16_) then
        t_16_ = t_16_.package
      else
      end
      if (nil ~= t_16_) then
        t_16_ = t_16_.loaded
      else
      end
      if (nil ~= t_16_) then
        t_16_ = t_16_.fennel
      else
      end
      _17_ = t_16_
    end
    local or_21_ = _17_ or _G.debug
    if not or_21_ then
      local function _22_()
        return ""
      end
      or_21_ = {traceback = _22_}
    end
    return close_handlers_12_(_G.xpcall(_15_, or_21_.traceback))
  end
  try(_13_)
end
do
  local cmd = _G.vim.api.nvim_create_user_command
  local function _23_(ev)
    local _let_24_ = require("elin.commands")
    local do_eval = _let_24_["do-eval"]
    do_eval(ev.bang, ev.args)
    return nil
  end
  cmd("Fnl", _23_, {nargs = "+", bang = true, desc = "fennel.eval {expression} to wherever"})
  local function _25_(ev)
    local _let_26_ = require("elin.commands")
    local do_files = _let_26_["do-files"]
    do_files(ev.bang, ev.fargs)
    return nil
  end
  cmd("FnlFiles", _25_, {nargs = "+", bang = true, complete = "file", desc = "fennel.eval files"})
  local function _27_(ev)
    local _let_28_ = require("elin.commands")
    local do_lines = _let_28_["do-lines"]
    do_lines(ev.bang, ev.line1, ev.line2, 0, ev.args)
    return nil
  end
  cmd("FnlLines", _27_, {nargs = "*", bang = true, range = "%", desc = "fennel.eval range"})
  local function _29_(ev)
    local _let_30_ = require("elin.commands")
    local do_swiss = _let_30_["do-swiss"]
    do_swiss(ev.bang, ev.count, ev.line1, ev.line2, 0, ev.args)
    return nil
  end
  cmd("FnlSwiss", _29_, {nargs = "*", bang = true, range = true, desc = "fennel.eval(<files [range] {expression}) to wherever"})
end
do
  local aug = _G.vim.api.nvim_create_augroup("elin", {})
  local au = _G.vim.api.nvim_create_autocmd
  local function _31_(_241)
    local _let_32_ = require("elin.ftplugin")
    local do_filetype_plugins = _let_32_["do-filetype-plugins"]
    return do_filetype_plugins(_241)
  end
  au("FileType", {group = aug, callback = _31_, desc = "load fennel files"})
  local function _33_(ev)
    elin.dofile(_G.vim.fs.normalize(ev.file, nil))
    return nil
  end
  au("SourceCmd", {group = aug, pattern = "*.fnl", callback = _33_, desc = ":source fennel files"})
end
return nil
