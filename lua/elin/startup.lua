if _G["_elin-did-startup"] then
  return
else
end
_G["_elin-did-startup"] = true
local elin = require("elin")
local fennel = require("fennel")
local function no_rtp_file(glob)
  return (_G.vim.api.nvim_get_runtime_file(glob, false)[1] == nil)
end
local function all_rtp_files(glob)
  return _G.vim.api.nvim_get_runtime_file(glob, true)
end
local function try(func)
  local function _2_(err)
    print(fennel.traceback, err)
    return err
  end
  return xpcall(func, _2_)
end
if (no_rtp_file("init.lua") and no_rtp_file("init.vim")) then
  local _3_ = _G.vim.api.nvim_get_runtime_file("init.fnl", false)
  if ((_G.type(_3_) == "table") and (nil ~= _3_[1])) then
    local file = _3_[1]
    _G.vim.uv.os_setenv("MYVIMRC", file)
    local function _4_()
      return elin.dofile(file)
    end
    try(_4_)
  else
  end
else
end
for _, path in ipairs(all_rtp_files("plugin/**/*.fnl")) do
  local function _7_()
    return elin.dofile(path)
  end
  try(_7_)
end
for _, path in ipairs(all_rtp_files("lsp/*.fnl")) do
  local function _8_()
    local file = _G.io.open(path)
    local function close_handlers_12_(ok_13_, ...)
      file:close()
      if ok_13_ then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _10_()
      local config = fennel.eval(file:read("*a"))
      local name = path:gsub(".*/", ""):gsub("%.fnl$", "")
      return _G.vim.lsp.config(name, config)
    end
    local _12_
    do
      local t_11_ = _G
      if (nil ~= t_11_) then
        t_11_ = t_11_.package
      else
      end
      if (nil ~= t_11_) then
        t_11_ = t_11_.loaded
      else
      end
      if (nil ~= t_11_) then
        t_11_ = t_11_.fennel
      else
      end
      _12_ = t_11_
    end
    local or_16_ = _12_ or _G.debug
    if not or_16_ then
      local function _17_()
        return ""
      end
      or_16_ = {traceback = _17_}
    end
    return close_handlers_12_(_G.xpcall(_10_, or_16_.traceback))
  end
  try(_8_)
end
do
  local cmd = _G.vim.api.nvim_create_user_command
  local function _18_(ev)
    local _let_19_ = require("elin.commands")
    local do_eval = _let_19_["do-eval"]
    do_eval(ev.bang, ev.args)
    return nil
  end
  cmd("Fnl", _18_, {nargs = "+", bang = true, desc = "fennel.eval {expression} to wherever"})
  local function _20_(ev)
    local _let_21_ = require("elin.commands")
    local do_files = _let_21_["do-files"]
    do_files(ev.bang, ev.fargs)
    return nil
  end
  cmd("FnlFiles", _20_, {nargs = "+", bang = true, complete = "file", desc = "fennel.eval files"})
  local function _22_(ev)
    local _let_23_ = require("elin.commands")
    local do_lines = _let_23_["do-lines"]
    do_lines(ev.bang, ev.line1, ev.line2, 0, ev.args)
    return nil
  end
  cmd("FnlLines", _22_, {nargs = "*", bang = true, range = "%", desc = "fennel.eval range"})
  local function _24_(ev)
    local _let_25_ = require("elin.commands")
    local do_swiss = _let_25_["do-swiss"]
    do_swiss(ev.bang, ev.count, ev.line1, ev.line2, 0, ev.args)
    return nil
  end
  cmd("FnlSwiss", _24_, {nargs = "*", bang = true, range = true, desc = "fennel.eval(<files [range] {expression}) to wherever"})
end
do
  local aug = _G.vim.api.nvim_create_augroup("elin", {})
  local au = _G.vim.api.nvim_create_autocmd
  local function _26_(_241)
    local _let_27_ = require("elin.ftplugin")
    local do_filetype_plugins = _let_27_["do-filetype-plugins"]
    return do_filetype_plugins(_241)
  end
  au("FileType", {group = aug, callback = _26_, desc = "load fennel files"})
  local function _28_(ev)
    elin.dofile(_G.vim.fs.normalize(ev.file, nil))
    return nil
  end
  au("SourceCmd", {group = aug, pattern = "*.fnl", callback = _28_, desc = ":source fennel files"})
end
return nil
