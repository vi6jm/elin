local fennel = require("fennel")
local uv = (vim.loop or vim.uv)
local elin = require("elin")
local _config = (vim.fn.stdpath("config") .. "/")
local _config_len = #_config
local _o755 = 493
local _fnl_files = "{fnl,plugin,ftplugin,syntax,colors,compile,lsp}/**/*.fnl"
local function _make_all_dirs(file, mode)
  local dirs = {}
  local dir = vim.fs.dirname(file)
  while (uv.fs_stat(dir) == nil) do
    table.insert(dirs, 1, dir)
    dir = vim.fs.dirname(dir)
  end
  for _, dir0 in ipairs(dirs) do
    uv.fs_mkdir(dir0, mode)
  end
  return nil
end
local function _fnl_to_lua_fname(fnl_fname)
  return (elin["cache-rtp"] .. fnl_fname:sub(_config_len):gsub("^fnl/", "lua/"):gsub("%.fnl$", ".lua"))
end
local function _compile_nvim(fnl_fname, opts)
  if (fnl_fname:sub(1, _config_len) == _config) then
    local fnl_fh = io.open(fnl_fname)
    local function close_handlers_12_(ok_13_, ...)
      fnl_fh:close()
      if ok_13_ then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _2_()
      local lua_fname = _fnl_to_lua_fname(fnl_fname)
      opts.filename = fnl_fname
      _make_all_dirs(lua_fname, _o755)
      local _3_, _4_ = nil, nil
      local function _5_()
        return fennel.compile(fnl_fh, opts)
      end
      local function _6_(_241)
        return _241
      end
      _3_, _4_ = xpcall(_5_, _6_)
      if ((_3_ == true) and (nil ~= _4_)) then
        local lua_out = _4_
        local lua_fh = io.open(lua_fname, "w")
        local function close_handlers_12_0(ok_13_, ...)
          lua_fh:close()
          if ok_13_ then
            return ...
          else
            return error(..., 0)
          end
        end
        local function _8_()
          lua_fh:write(lua_out)
          lua_fh:write("\n")
          return {true, nil, fnl_fname, lua_fname}
        end
        local _10_
        do
          local t_9_ = _G
          if (nil ~= t_9_) then
            t_9_ = t_9_.package
          else
          end
          if (nil ~= t_9_) then
            t_9_ = t_9_.loaded
          else
          end
          if (nil ~= t_9_) then
            t_9_ = t_9_.fennel
          else
          end
          _10_ = t_9_
        end
        local or_14_ = _10_ or _G.debug
        if not or_14_ then
          local function _15_()
            return ""
          end
          or_14_ = {traceback = _15_}
        end
        return close_handlers_12_0(_G.xpcall(_8_, or_14_.traceback))
      elseif (true and (nil ~= _4_)) then
        local _ = _3_
        local err = _4_
        if elin.verbose then
          local qname = string.format("%q", fnl_fname)
          print(("error compiling " .. qname .. ": " .. err))
        else
        end
        return {false, err, fnl_fname, nil}
      else
        return nil
      end
    end
    local _19_
    do
      local t_18_ = _G
      if (nil ~= t_18_) then
        t_18_ = t_18_.package
      else
      end
      if (nil ~= t_18_) then
        t_18_ = t_18_.loaded
      else
      end
      if (nil ~= t_18_) then
        t_18_ = t_18_.fennel
      else
      end
      _19_ = t_18_
    end
    local or_23_ = _19_ or _G.debug
    if not or_23_ then
      local function _24_()
        return ""
      end
      or_23_ = {traceback = _24_}
    end
    return close_handlers_12_(_G.xpcall(_2_, or_23_.traceback))
  else
    if elin.verbose then
      print(("error before compiling: file not `config` dir: " .. fnl_fname))
    else
    end
    return {false, ("file not in nvim `config` dir: " .. fnl_fname), fnl_fname, nil}
  end
end
local function _gather_opts(opts)
  local opts0 = (opts or {})
  if (opts0.allowGlobals == true) then
    local tbl_21_ = {}
    local i_22_ = 0
    for g, _ in pairs(_G) do
      local val_23_ = g
      if (nil ~= val_23_) then
        i_22_ = (i_22_ + 1)
        tbl_21_[i_22_] = val_23_
      else
      end
    end
    opts0.allowGlobals = tbl_21_
  else
  end
  return opts0
end
local function compile_nvim_config(opts)
  local tbl_21_ = {}
  local i_22_ = 0
  for _, fnl_fname in ipairs(vim.api.nvim_get_runtime_file(_fnl_files, true)) do
    local val_23_ = _compile_nvim(fnl_fname, _gather_opts(opts))
    if (nil ~= val_23_) then
      i_22_ = (i_22_ + 1)
      tbl_21_[i_22_] = val_23_
    else
    end
  end
  return tbl_21_
end
local function compile_nvim_file(fnl_fname, opts)
  return _compile_nvim(fnl_fname, _gather_opts(opts))
end
return {["compile-nvim-config"] = compile_nvim_config, compileNvimConfig = compile_nvim_config, ["compile-nvim-file"] = compile_nvim_file, compileNvimFile = compile_nvim_file}
