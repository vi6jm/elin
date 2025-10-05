local fennel = require("fennel")
local function try(func)
  local function _1_(err)
    print(fennel.traceback, err)
    return err
  end
  return xpcall(func, _1_)
end
local function undo_ft_plugin(ev, typ)
  local undo_fnl = _G.vim.b[ev.buf][("undo_" .. typ .. "_fnl")]
  local undo_lua = _G.vim.b[ev.buf][("undo_" .. typ .. "_lua")]
  if (undo_fnl or undo_lua) then
    if (type(undo_fnl) == "string") then
      local function _2_()
        return fennel.eval(undo_fnl)
      end
      try(_2_)
    elseif (type(undo_fnl) == "function") then
      local function _3_()
        return undo_fnl()
      end
      try(_3_)
    elseif (type(undo_lua) == "string") then
      local function _4_()
        return _G.vim.fn.luaeval(undo_lua, nil)
      end
      try(_4_)
    elseif (type(undo_lua) == "function") then
      local function _5_()
        return undo_lua()
      end
      try(_5_)
    else
    end
    _G.vim.b[ev.buf][("undo_" .. typ .. "_fnl")] = nil
    _G.vim.b[ev.buf][("undo_" .. typ .. "_lua")] = nil
    return nil
  else
    return nil
  end
end
local function do_ft_plugin(ev, typ)
  for ft in _G.string.gmatch(ev.match, "[^.]+") do
    local paths = _G.vim.api.nvim_get_runtime_file(_G.string.format("%s/%s.fnl %s/%s_*.fnl", typ, ft, typ, ft), true)
    for _, path in ipairs(paths) do
      local function _8_()
        return fennel.dofile(path)
      end
      try(_8_)
    end
  end
  return nil
end
local function do_syntax(ev)
  for ft in _G.string.gmatch(ev.match, "[^.]+") do
    local paths = _G.vim.api.nvim_get_runtime_file(_G.string.format("syntax/%s.fnl", ft), true)
    for _, path in ipairs(paths) do
      local function _9_()
        return fennel.dofile(path)
      end
      try(_9_)
    end
  end
  return nil
end
local function do_filetype_plugins(ev)
  local ftp_on
  do
    local on = _G.vim.g.did_load_ftplugin
    ftp_on = ((on == 1) or (on == true))
  end
  local ind_on
  do
    local on = _G.vim.g.did_indent_on
    ind_on = ((on == 1) or (on == true))
  end
  local syn_on
  do
    local on = _G.vim.g.syntax_on
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
    do_syntax(ev)
  else
  end
  return nil
end
return {["do-filetype-plugins"] = do_filetype_plugins}
