if _G["_elin-did-startup"] then
  return
else
end
_G["_elin-did-startup"] = true
local fennel
do
  local fs_open = _G.vim.uv["fs_open"]
  local fs_fstat = _G.vim.uv["fs_fstat"]
  local fs_read = _G.vim.uv["fs_read"]
  local fs_close = _G.vim.uv["fs_close"]
  local fs_write = _G.vim.uv["fs_write"]
  local _2_ = _G.vim.api.nvim_get_runtime_file("lua/fennel.luac", false)[1]
  if (nil ~= _2_) then
    local path = _2_
    local fh = fs_open(path, "r", 438)
    local size = assert(fs_fstat(fh)).size
    local data = fs_read(fh, size, 0)
    fs_close(fh)
    local _3_ = _G.loadstring(data)
    if (nil ~= _3_) then
      local f = _3_
      fennel = f()
    else
      fennel = nil
    end
  else
    local _ = _2_
    local _5_ = _G.vim.api.nvim_get_runtime_file("lua/fennel.lua", false)[1]
    if (nil ~= _5_) then
      local path = _5_
      local cpath = (path .. "c")
      local fh = fs_open(cpath, "w", 438)
      local f = loadfile(path)
      fs_write(fh, string.dump(f, true))
      fs_close(fh)
      fennel = f()
    else
      local _0 = _5_
      print("Fatal: unable to find fennel.lua module")
      fennel = nil
    end
  end
end
_G.package.loaded.fennel = fennel
local elin = require("elin")
do
  local config = _G.vim.fn.stdpath("config")
  fennel.path = (config .. "/fnl/?.fnl;" .. config .. "/fnl/?/init.fnl")
end
fennel.install()
local function no_rtp_file(glob)
  return (_G.vim.api.nvim_get_runtime_file(glob, false)[1] == nil)
end
local function all_rtp_files(glob)
  return _G.vim.api.nvim_get_runtime_file(glob, true)
end
local function try(func)
  local function _8_(err)
    print(fennel.traceback, err)
    return err
  end
  return xpcall(func, _8_)
end
if (no_rtp_file("init.lua") and no_rtp_file("init.vim")) then
  local _9_ = _G.vim.api.nvim_get_runtime_file("init.fnl", false)
  if ((_G.type(_9_) == "table") and (nil ~= _9_[1])) then
    local file = _9_[1]
    _G.vim.uv.os_setenv("MYVIMRC", file)
    local function _10_()
      return elin.dofile(file)
    end
    try(_10_)
  else
  end
else
end
for _, path in ipairs(all_rtp_files("plugin/**/*.fnl")) do
  local function _13_()
    return elin.dofile(path)
  end
  try(_13_)
end
for _, path in ipairs(all_rtp_files("lsp/*.fnl")) do
  local function _14_()
    local file = _G.io.open(path)
    local function close_handlers_12_(ok_13_, ...)
      file:close()
      if ok_13_ then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _16_()
      local config = fennel.eval(file:read("*a"))
      local name = path:gsub(".*/", ""):gsub("%.fnl$", "")
      return _G.vim.lsp.config(name, config)
    end
    local _18_
    do
      local t_17_ = _G
      if (nil ~= t_17_) then
        t_17_ = t_17_.package
      else
      end
      if (nil ~= t_17_) then
        t_17_ = t_17_.loaded
      else
      end
      if (nil ~= t_17_) then
        t_17_ = t_17_.fennel
      else
      end
      _18_ = t_17_
    end
    local or_22_ = _18_ or _G.debug
    if not or_22_ then
      local function _23_()
        return ""
      end
      or_22_ = {traceback = _23_}
    end
    return close_handlers_12_(_G.xpcall(_16_, or_22_.traceback))
  end
  try(_14_)
end
do
  local cmd = _G.vim.api.nvim_create_user_command
  local function _24_(ev)
    local _let_25_ = require("elin.commands")
    local do_eval = _let_25_["do-eval"]
    do_eval(ev.bang, ev.args)
    return nil
  end
  cmd("Fnl", _24_, {nargs = "+", bang = true, desc = "fennel.eval {expression} to wherever"})
  local function _26_(ev)
    local _let_27_ = require("elin.commands")
    local do_files = _let_27_["do-files"]
    do_files(ev.bang, ev.fargs)
    return nil
  end
  cmd("FnlFiles", _26_, {nargs = "+", bang = true, complete = "file", desc = "fennel.eval files"})
  local function _28_(ev)
    local _let_29_ = require("elin.commands")
    local do_lines = _let_29_["do-lines"]
    do_lines(ev.bang, ev.line1, ev.line2, 0, ev.args)
    return nil
  end
  cmd("FnlLines", _28_, {nargs = "*", bang = true, range = "%", desc = "fennel.eval range"})
  local function _30_(ev)
    local _let_31_ = require("elin.commands")
    local do_swiss = _let_31_["do-swiss"]
    do_swiss(ev.bang, ev.count, ev.line1, ev.line2, 0, ev.args)
    return nil
  end
  cmd("FnlSwiss", _30_, {nargs = "*", bang = true, range = true, desc = "fennel.eval(<files [range] {expression}) to wherever"})
end
do
  local aug = _G.vim.api.nvim_create_augroup("elin", {})
  local au = _G.vim.api.nvim_create_autocmd
  local function _32_(_241)
    local _let_33_ = require("elin.ftplugin")
    local do_filetype_plugins = _let_33_["do-filetype-plugins"]
    return do_filetype_plugins(_241)
  end
  au("FileType", {group = aug, callback = _32_, desc = "load fennel files"})
  local function _34_(ev)
    elin.dofile(_G.vim.fs.normalize(ev.file, nil))
    return nil
  end
  au("SourceCmd", {group = aug, pattern = "*.fnl", callback = _34_, desc = ":source fennel files"})
end
return nil
