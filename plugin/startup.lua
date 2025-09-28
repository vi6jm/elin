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
else
end
for _, path in ipairs(all_rtp_files("lsp/*.fnl")) do
  local function _9_()
    local file = io.open(path)
    local function close_handlers_12_(ok_13_, ...)
      file:close()
      if ok_13_ then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _11_()
      local config0 = fennel.eval(file:read("*a"))
      local name = path:gsub(".*/", ""):gsub("%.fnl$", "")
      return vim.lsp.config(name, config0)
    end
    local _13_
    do
      local t_12_ = _G
      if (nil ~= t_12_) then
        t_12_ = t_12_.package
      else
      end
      if (nil ~= t_12_) then
        t_12_ = t_12_.loaded
      else
      end
      if (nil ~= t_12_) then
        t_12_ = t_12_.fennel
      else
      end
      _13_ = t_12_
    end
    local or_17_ = _13_ or _G.debug
    if not or_17_ then
      local function _18_()
        return ""
      end
      or_17_ = {traceback = _18_}
    end
    return close_handlers_12_(_G.xpcall(_11_, or_17_.traceback))
  end
  try(_9_)
end
local function undo_ft_plugin(ev, typ)
  local undo_fnl = vim.b[ev.buf][("undo_" .. typ .. "_fnl")]
  local undo_lua = vim.b[ev.buf][("undo_" .. typ .. "_lua")]
  if (undo_fnl or undo_lua) then
    if (type(undo_fnl) == "string") then
      local function _19_()
        return fennel.eval(undo_fnl)
      end
      try(_19_)
    elseif (type(undo_fnl) == "function") then
      local function _20_()
        return undo_fnl()
      end
      try(_20_)
    elseif (type(undo_lua) == "string") then
      local function _21_()
        return vim.fn.luaeval(undo_lua, nil)
      end
      try(_21_)
    elseif (type(undo_lua) == "function") then
      local function _22_()
        return undo_lua()
      end
      try(_22_)
    else
    end
    vim.b[ev.buf][("undo_" .. typ .. "_fnl")] = nil
    vim.b[ev.buf][("undo_" .. typ .. "_lua")] = nil
    return nil
  else
    return nil
  end
end
local function do_ft_plugin(ev, typ)
  for ft in string.gmatch(ev.match, "[^.]+") do
    local paths = vim.api.nvim_get_runtime_file(string.format("%s/%s.fnl %s/%s_*.fnl", typ, ft, typ, ft), true)
    for _, path in ipairs(paths) do
      local function _25_()
        return fennel.dofile(path)
      end
      try(_25_)
    end
  end
  return nil
end
local function do_syntax(ev)
  for ft in string.gmatch(ev.match, "[^.]+") do
    local paths = vim.api.nvim_get_runtime_file(string.format("syntax/%s.fnl", ft), true)
    for _, path in ipairs(paths) do
      local function _26_()
        return fennel.dofile(path)
      end
      try(_26_)
    end
  end
  return nil
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
    undo_ft_plugin(ev, "ftplugin")
    do_ft_plugin(ev, "ftplugin")
    if ind_on then
      undo_ft_plugin(ev, "indent")
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
  local function _30_(ev)
    local _let_31_ = require("elin.commands")
    local do_eval = _let_31_["do-eval"]
    do_eval(ev.bang, ev.args)
    return nil
  end
  cmd("Fnl", _30_, {nargs = "+", bang = true, desc = "fennel.eval {expression} to wherever"})
  local function _32_(ev)
    local _let_33_ = require("elin.commands")
    local do_files = _let_33_["do-files"]
    do_files(ev.bang, ev.fargs)
    return nil
  end
  cmd("FnlFiles", _32_, {nargs = "+", bang = true, complete = "file", desc = "fennel.eval files"})
  local function _34_(ev)
    local _let_35_ = require("elin.commands")
    local do_lines = _let_35_["do-lines"]
    do_lines(ev.bang, ev.line1, ev.line2, 0, ev.args)
    return nil
  end
  cmd("FnlLines", _34_, {nargs = "*", bang = true, range = "%", desc = "fennel.eval range"})
  local function _36_(ev)
    local _let_37_ = require("elin.commands")
    local do_swiss = _let_37_["do-swiss"]
    do_swiss(ev.bang, ev.count, ev.line1, ev.line2, 0, ev.args)
    return nil
  end
  cmd("FnlSwiss", _36_, {nargs = "*", bang = true, range = true, desc = "fennel.eval(<files [range] {expression}) to wherever"})
end
do
  local aug = vim.api.nvim_create_augroup("elin", {})
  local au = vim.api.nvim_create_autocmd
  local function _38_(...)
    return do_filetype_plugins(...)
  end
  au("FileType", {group = aug, callback = _38_, desc = "load fennel files"})
  local function _39_(ev)
    fennel.dofile(vim.fs.normalize(ev.file, nil))
    return nil
  end
  au("SourceCmd", {group = aug, pattern = "*.fnl", callback = _39_, desc = ":source fennel files"})
end
return nil
