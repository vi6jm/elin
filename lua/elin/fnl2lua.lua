local ignore_dirs = {vim.fn.stdpath("config")}
local markers = {".git/", "flsproject.fnl", "init.fnl"}
local function set_ignore_dirs(ignores)
  do
    local _1_ = type(ignores)
    local and_2_ = (nil ~= _1_)
    if and_2_ then
      local t = _1_
      and_2_ = ((t == "nil") or (t == "table"))
    end
    if and_2_ then
      local t = _1_
      ignore_dirs = ignores
    else
      local _ = _1_
      print("Error: set-ignore-dirs expected `nil` or a table")
    end
  end
  return nil
end
local function add_ignore_dir(dir)
  if (type(ignore_dirs) ~= "table") then
    ignore_dirs = {}
  else
  end
  return table.insert(ignore_dirs, dir)
end
local function _list_index(list, pat)
  local res = nil
  for idx, val in ipairs(list) do
    if res then break end
    if (val == pat) then
      res = idx
    else
    end
  end
  return res
end
local function remove_ignore_dir(dir)
  if (type(ignore_dirs) == "table") then
    local _7_ = _list_index(ignore_dirs, dir)
    if (nil ~= _7_) then
      local idx = _7_
      return table.remove(ignore_dirs, idx)
    else
      return nil
    end
  else
    ignore_dirs = nil
    return nil
  end
end
local function get_ignore_dirs()
  local tbl_21_ = {}
  local i_22_ = 0
  for _, v in ipairs(ignore_dirs) do
    local val_23_ = v
    if (nil ~= val_23_) then
      i_22_ = (i_22_ + 1)
      tbl_21_[i_22_] = val_23_
    else
    end
  end
  return tbl_21_
end
local function _fs_dir_has_file(source, file)
  local path = (source .. "/" .. file)
  local is_dir_3f = vim.endswith(file, "/")
  local _11_ = vim.uv.fs_stat(path)
  if (_11_ == nil) then
    return false
  elseif (nil ~= _11_) then
    local stat = _11_
    if is_dir_3f then
      return (stat.type == "directory")
    else
      return (((stat.type == "file") or (stat.type == "link")) and (nil ~= vim.uv.fs_access(path, "R")))
    end
  else
    return nil
  end
end
local function _fs_last_root(source)
  local res = nil
  for dir in vim.fs.parents(source) do
    if res then break end
    for _, marker in ipairs(markers) do
      if res then break end
      if _fs_dir_has_file(dir, marker) then
        res = dir
      else
      end
    end
  end
  return res
end
local function werr(msg)
  return _G.vim.api.nvim_echo({{msg}}, true, {err = true, kind = "errormsg"})
end
local function compile(file)
  do
    local filename = vim.fs.abspath(file)
    local dir = vim.fs.dirname(filename)
    local _15_ = _fs_last_root(dir)
    if (nil ~= _15_) then
      local root = _15_
      if not vim.list_contains(ignore_dirs, root) then
        local rel_file = filename:sub((2 + #root))
        local rel_file0 = rel_file:gsub("^fnl/", "")
        local rel_file1 = rel_file0:gsub("%.fnl$", "")
        local rel_file2 = (rel_file1 .. ".lua")
        local fout_name = (root .. "/lua/" .. rel_file2)
        local _let_16_ = require("fennel")
        local compile0 = _let_16_["compile"]
        local traceback = _let_16_["traceback"]
        vim.fn.mkdir(vim.fs.dirname(fout_name), "p")
        local fin = io.open(filename)
        local fout = io.open(fout_name, "w")
        local function close_handlers_12_(ok_13_, ...)
          fout:close()
          fin:close()
          if ok_13_ then
            return ...
          else
            return error(..., 0)
          end
        end
        local function _18_()
          local _19_, _20_ = nil, nil
          local function _21_()
            return compile0(fin, {filename = filename})
          end
          local function _22_(err)
            werr(traceback(err))
            return err
          end
          _19_, _20_ = xpcall(_21_, _22_)
          if ((_19_ == true) and (nil ~= _20_)) then
            local code = _20_
            return fout:write(code)
          elseif (true and (nil ~= _20_)) then
            local _ = _19_
            local err = _20_
            return nil, err
          else
            return nil
          end
        end
        local _25_
        do
          local t_24_ = _G
          if (nil ~= t_24_) then
            t_24_ = t_24_.package
          else
          end
          if (nil ~= t_24_) then
            t_24_ = t_24_.loaded
          else
          end
          if (nil ~= t_24_) then
            t_24_ = t_24_.fennel
          else
          end
          _25_ = t_24_
        end
        local or_29_ = _25_ or _G.debug
        if not or_29_ then
          local function _30_()
            return ""
          end
          or_29_ = {traceback = _30_}
        end
        close_handlers_12_(_G.xpcall(_18_, or_29_.traceback))
      else
      end
    else
    end
  end
  return nil
end
local function enable(callback_3f)
  local group = _G.vim.api.nvim_create_augroup("elin_fnl2lua", {})
  local callback = (callback_3f or compile)
  _G["___elin-fnl2lua-auid___"] = group
  local function _33_(_241)
    return callback(vim.fs.normalize(_241.file))
  end
  return _G.vim.api.nvim_create_autocmd("BufWritePost", {pattern = "*.fnl", group = group, callback = _33_})
end
local function disable()
  if _G["___elin-fnl2lua-auid___"] then
    do local _ = _G.vim.api.nvim_clear_autocmd end
    do local _ = {group = _G["___elin-fnl2lua-auid___"]} end
  else
  end
  _G["___elin-fnl2lua-auid___"] = nil
  return nil
end
local function set_project_markers(m)
  if (type(m) == "table") then
    markers = m
    return nil
  else
    return nil
  end
end
return {enable = enable, disable = disable, ["set-ignore-dirs"] = set_ignore_dirs, ["add-ignore-dir"] = add_ignore_dir, ["remove-ignore-dir"] = remove_ignore_dir, ["get-ignore-dirs"] = get_ignore_dirs, ["set-project-markers"] = set_project_markers, compile = compile}