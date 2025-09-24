if _G["_elin-did-startup"] then
  return
else
end
_G["_elin-did-startup"] = true
local fennel = require("fennel")
local config = vim.fn.stdpath("config")
fennel.path = (config .. "/fnl/?.fnl;" .. config .. "/fnl/?/init.fnl")
fennel.install()
local function no_rtp_file(glob)
  return (vim.api.nvim_get_runtime_file(glob, false)[1] == nil)
end
local function all_rtp_files(glob)
  return vim.api.nvim_get_runtime_file(glob, true)
end
local function try(func)
  local function _2_(err)
    print(fennel.traceback, err)
    return err
  end
  return xpcall(func, _2_)
end
if (no_rtp_file("init.lua") and no_rtp_file("init.vim")) then
  local _3_ = vim.api.nvim_get_runtime_file("init.fnl", false)
  if ((_G.type(_3_) == "table") and (nil ~= _3_[1])) then
    local file = _3_[1]
    vim.uv.os_setenv("MYVIMRC", file)
    local function _4_()
      return fennel.dofile(file)
    end
    try(_4_)
  else
  end
else
end
if vim.o.loadplugins then
  for _, path in ipairs(all_rtp_files("plugin/**/*.fnl")) do
    local function _7_()
      return fennel.dofile(path)
    end
    try(_7_)
  end
  for _, path in ipairs(all_rtp_files("after/plugin/**/*.fnl")) do
    local function _8_()
      return fennel.dofile(path)
    end
    try(_8_)
  end
else
end
for _, path in ipairs(all_rtp_files("lsp/*.fnl")) do
  local function _10_()
    local file = io.open(path)
    local function close_handlers_12_(ok_13_, ...)
      file:close()
      if ok_13_ then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _12_()
      local config0 = fennel.eval(file:read("*a"))
      local name = path:gsub(".*/", ""):gsub("%.fnl$", "")
      return vim.lsp.config(name, config0)
    end
    local _14_
    do
      local t_13_ = _G
      if (nil ~= t_13_) then
        t_13_ = t_13_.package
      else
      end
      if (nil ~= t_13_) then
        t_13_ = t_13_.loaded
      else
      end
      if (nil ~= t_13_) then
        t_13_ = t_13_.fennel
      else
      end
      _14_ = t_13_
    end
    local or_18_ = _14_ or _G.debug
    if not or_18_ then
      local function _19_()
        return ""
      end
      or_18_ = {traceback = _19_}
    end
    return close_handlers_12_(_G.xpcall(_12_, or_18_.traceback))
  end
  try(_10_)
end
local function do_undo_ft_plugin(ev, typ)
  local undo_fnl = vim.b[ev.buf][("undo_" .. typ .. "_fnl")]
  local undo_lua = vim.b[ev.buf][("undo_" .. typ .. "_lua")]
  if (undo_fnl or undo_lua) then
    if (type(undo_fnl) == "string") then
      local function _20_()
        return fennel.eval(undo_fnl)
      end
      try(_20_)
    elseif (type(undo_fnl) == "function") then
      local function _21_()
        return undo_fnl()
      end
      try(_21_)
    elseif (type(undo_lua) == "string") then
      local function _22_()
        return vim.fn.luaeval(undo_lua, nil)
      end
      try(_22_)
    elseif (type(undo_lua) == "function") then
      local function _23_()
        return undo_lua()
      end
      try(_23_)
    else
    end
    vim.b[ev.buf][("undo_")(typ, "_fnl")] = nil
    vim.b[ev.buf][("undo_")(typ, "_lua")] = nil
    vim.b[ev.buf][("undo_")(typ)] = nil
    return nil
  else
    return nil
  end
end
local function do_ft_plugin(ev, typ)
  local glob = vim.api.nvim_get_runtime_file((typ .. "/" .. ev.match .. ".fnl"), false)[1]
  local aglob = vim.api.nvim_get_runtime_file(("after/" .. typ .. "/" .. ev.match .. ".fnl"), false)[1]
  if (nil ~= glob) then
    local path = glob
    local function _26_()
      return fennel.dofile(path)
    end
    try(_26_)
  else
  end
  if (nil ~= aglob) then
    local path = aglob
    local function _28_()
      return fennel.dofile(path)
    end
    return try(_28_)
  else
    return nil
  end
end
local function do_syntax(ev)
  local syng = vim.api.nvim_get_runtime_file(("syntax/" .. ev.match .. ".fnl"), false)[1]
  local asyng = vim.api.nvim_get_runtime_file(("after/syntax" .. ev.match .. ".fnl"), false)[1]
  if (nil ~= syng) then
    local path = syng
    local function _30_()
      return fennel.dofile(path)
    end
    try(_30_)
  else
  end
  if (nil ~= asyng) then
    local path = asyng
    local function _32_()
      return fennel.dofile(path)
    end
    return try(_32_)
  else
    return nil
  end
end
local function do_filetype_plugins(ev)
  local ftp_on
  do
    local on = vim.g.did_load_ftplugin
    ftp_on = ((on == 1) or (on == true))
  end
  local ind_on
  do
    local on = vim.g.did_indent_on
    ind_on = ((on == 1) or (on == true))
  end
  local syn_on
  do
    local on = vim.g.syntax_on
    syn_on = ((on == 1) or (on == true))
  end
  if ftp_on then
    do_undo_ft_plugin(ev, "ftplugin")
    do_ft_plugin(ev, "ftplugin")
    if ind_on then
      do_undo_ft_plugin(ev, "indent")
      do_ft_plugin(ev, "indent")
    else
    end
  else
  end
  if syn_on then
    return do_syntax(ev)
  else
    return nil
  end
end
do
  local cmd = vim.api.nvim_create_user_command
  local function _37_(_241)
    local _let_38_ = require("elin.commands")
    local fnl = _let_38_["fnl"]
    return fnl(_241.args, _241.reg)
  end
  cmd("Fnl", _37_, {nargs = 1, bar = true, register = true, desc = "fennel.eval {expression} to cmdline or register"})
  local function _39_(_241)
    local _let_40_ = require("elin.commands")
    local dofile = _let_40_["dofile"]
    return dofile(_241.args, "")
  end
  cmd("FnlDofile", _39_, {nargs = 1, complete = "file", desc = ":fennel.dofile {file} to cmdline or register"})
  local function _41_(_241)
    local _let_42_ = require("elin.commands")
    local dofile = _let_42_["dofile"]
    return dofile(_241.args, _241.reg)
  end
  cmd("FnlDofileReg", _41_, {nargs = 1, complete = "file", register = true, desc = ":fennel.dofile {file} to cmdline or register"})
  local function _43_(_241)
    local _let_44_ = require("elin.commands")
    local dolines = _let_44_["dolines"]
    return dolines(_241.line1, _241.line2, 0, _241.reg)
  end
  cmd("FnlDolines", _43_, {nargs = 0, bar = true, range = true, register = true, desc = "fennel.eval [range] to cmdline or register"})
end
do
  local aug = vim.api.nvim_create_augroup("elin", {})
  local au = vim.api.nvim_create_autocmd
  local function _45_(...)
    return do_filetype_plugins(...)
  end
  au("FileType", {group = aug, callback = _45_, desc = "load fennel files"})
  local function _46_(_241)
    return fennel.dofile(vim.fs.normalize(_241.file, nil))
  end
  au("SourceCmd", {group = aug, pattern = "*.fnl", callback = _46_, desc = ":source fennel files"})
end
return nil
