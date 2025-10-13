local version = "v0.0.7"
local fs_stat = _G.vim.uv["fs_stat"]
local fs_fstat = _G.vim.uv["fs_fstat"]
local fs_open = _G.vim.uv["fs_open"]
local fs_read = _G.vim.uv["fs_read"]
local fs_write = _G.vim.uv["fs_write"]
local fs_close = _G.vim.uv["fs_close"]
local get_rtp_file = _G.vim.api.nvim_get_runtime_file
local loaders = (_G.package.loaders or _G.package.searchers)
local caching_enabled = false
local cache_dir = (_G.vim.fn.stdpath("cache") .. "/elin/")
local function get_version()
  return version
end
local function get_cache_dir()
  return cache_dir
end
local function caching_enabled_3f()
  return caching_enabled
end
local function werr(msg)
  return _G.vim.api.nvim_echo({{msg}}, true, {err = true, kind = "errormsg"})
end
local function readfile(path, mode)
  local fh = fs_open(path, "r", mode)
  if fh then
    local size = assert(fs_fstat(fh)).size
    local data = fs_read(fh, size, 0)
    fs_close(fh)
    return data
  else
    return nil
  end
end
local function get_cache_path(path)
  local cpath
  local function _2_(_241)
    return string.format("%%%x", string.byte(_241))
  end
  cpath = path:gsub("%A", _2_)
  return (cache_dir .. cpath .. ".luac")
end
local function get_uncache_path(cpath)
  local path = cpath:gsub("%.luac?$", "")
  local function _3_(_241)
    return string.char(tonumber(_241, 16))
  end
  return path:gsub(".*/", ""):gsub("%.luac?$", ""):gsub("%%(%x%x)", _3_)
end
local function write_cache(path, cpath, _3fopts)
  local fh = _G.io.open(path)
  local function close_handlers_12_(ok_13_, ...)
    fh:close()
    if ok_13_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _5_()
    local _let_6_ = require("fennel")
    local compile = _let_6_["compile"]
    local traceback = _let_6_["traceback"]
    local _7_, _8_ = nil, nil
    local function _9_()
      return compile(fh, (_3fopts or {filename = path, correlate = true}))
    end
    local function _10_(err)
      werr(traceback(err))
      return err
    end
    _7_, _8_ = xpcall(_9_, _10_)
    if ((_7_ == true) and (nil ~= _8_)) then
      local code = _8_
      local fh0 = fs_open(cpath, "w", 438)
      local f = _G.loadstring(code)
      fs_write(fh0, string.dump(f, true))
      fs_close(fh0)
      return f
    elseif (true and (nil ~= _8_)) then
      local _ = _7_
      local err = _8_
      return nil, err
    else
      return nil
    end
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
  return close_handlers_12_(_G.xpcall(_5_, or_17_.traceback))
end
local function dofile_cached(path, _3fopts)
  local cpath = get_cache_path(path)
  local cstat = fs_stat(cpath)
  local stat = fs_stat(path)
  local _19_
  if ((cstat == nil) or (cstat.mtime.sec < stat.mtime.sec) or (cstat.mtime.nsec < stat.mtime.nsec)) then
    _19_ = write_cache(path, cpath, _3fopts)
  else
    _19_ = _G.loadstring(readfile(cpath, 438))
  end
  if (nil ~= _19_) then
    local f = _19_
    return f()
  else
    return nil
  end
end
local function dofile(path, _3fopts)
  local f
  if caching_enabled then
    f = dofile_cached
  else
    f = require("fennel").dofile
  end
  return f(path, _3fopts)
end
local function loader(mod)
  local mod0 = mod:gsub("^[/.]+", ""):gsub("%.", "/")
  local _23_ = get_rtp_file(("fnl/" .. mod0 .. ".fnl" .. " fnl/" .. mod0 .. "/init.fnl"), false)[1]
  if (nil ~= _23_) then
    local path = _23_
    local cpath = get_cache_path(path)
    local cstat = fs_stat(cpath)
    local stat = fs_stat(path)
    if ((cstat == nil) or (cstat.mtime.sec < stat.mtime.sec) or (cstat.mtime.nsec < stat.mtime.nsec)) then
      return write_cache(path, cpath)
    else
      return readfile(cpath, 438)
    end
  else
    return nil
  end
end
local function disable_caching()
  do
    local tbl_21_ = {}
    local i_22_ = 0
    for _, l in ipairs(loaders) do
      local val_23_
      if (l ~= loader) then
        val_23_ = loader
      else
        val_23_ = nil
      end
      if (nil ~= val_23_) then
        i_22_ = (i_22_ + 1)
        tbl_21_[i_22_] = val_23_
      else
      end
    end
    _G.package.loaders = tbl_21_
  end
  caching_enabled = false
  return nil
end
local function enable_caching()
  if caching_enabled then
    disable_caching()
  else
  end
  _G.table.insert(_G.package.loaders, 2, loader)
  caching_enabled = true
  return nil
end
local function try(func)
  local _let_29_ = require("fennel")
  local traceback = _let_29_["traceback"]
  local function _30_(err)
    print(traceback, err)
    return err
  end
  return xpcall(func, _30_)
end
local function setup(opts)
  do
    local ec = (opts["enable-caching"] or opts.enableCaching)
    local f
    if ec then
      f = enable_caching
    else
      f = disable_caching
    end
    f()
  end
  local cd = (opts["cache-dir"] or opts.cacheDir)
  if (type(cd) == "string") then
    cache_dir = (cd:gsub("/+$", "") .. "/")
    return nil
  else
    return nil
  end
end
local function do_startup(_3fopts)
  local did_startup = _G["___elin-did-startup___"]
  if (did_startup == nil) then
    _G["___elin-did-startup___"] = true
    local fs_open0 = _G.vim.uv["fs_open"]
    local fs_fstat0 = _G.vim.uv["fs_fstat"]
    local fs_read0 = _G.vim.uv["fs_read"]
    local fs_close0 = _G.vim.uv["fs_close"]
    local fs_write0 = _G.vim.uv["fs_write"]
    local _33_ = _G.vim.api.nvim_get_runtime_file("lua/fennel.luac", false)[1]
    if (nil ~= _33_) then
      local path = _33_
      local fh = fs_open0(path, "r", 438)
      local size = assert(fs_fstat0(fh)).size
      local data = fs_read0(fh, size, 0)
      fs_close0(fh)
      local _34_ = _G.loadstring(data)
      if (nil ~= _34_) then
        local f = _34_
        _G.package.loaded.fennel = f()
      else
        _G.package.loaded.fennel = nil
      end
    else
      local _ = _33_
      local _36_ = _G.vim.api.nvim_get_runtime_file("lua/fennel.lua", false)[1]
      if (nil ~= _36_) then
        local path = _36_
        local cpath = (path .. "c")
        local fh = fs_open0(cpath, "w", 438)
        local f = loadfile(path)
        fs_write0(fh, _G.string.dump(f, true))
        fs_close0(fh)
        _G.package.loaded.fennel = f()
      else
        local _0 = _36_
        print("Fatal: unable to find fennel.lua module")
        _G.package.loaded.fennel = nil
      end
    end
  else
  end
  local fennel = require("fennel")
  local opts = (_3fopts or {})
  local config = _G.vim.fn.stdpath("config")
  if ((did_startup == nil) or opts.force) then
    vim.fn.mkdir(cache_dir, "p")
    fennel.path = (config .. "/fnl/?.fnl;" .. config .. "/fnl/?/init.fnl")
    fennel.install()
    if (opts["load-init-fnl"] or opts.loadInitFnl or ((fs_stat((config .. "/init.lua")) == nil) and (fs_stat((config .. "/init.vim")) == nil))) then
      local init_path = (config .. "/init.fnl")
      if fs_stat(init_path) then
        _G.vim.uv.os_setenv("MYVIMRC", init_path)
        local function _40_()
          return dofile(init_path)
        end
        try(_40_)
      else
      end
    else
    end
    local get_rtp_file0 = _G.vim.api.nvim_get_runtime_file
    for _, path in ipairs(get_rtp_file0("plugin/**/*.fnl", true)) do
      local function _43_()
        return dofile(path)
      end
      try(_43_)
    end
    for _, path in ipairs(get_rtp_file0("lsp/*.fnl", true)) do
      local function _44_()
        local file = _G.io.open(path)
        local function close_handlers_12_(ok_13_, ...)
          file:close()
          if ok_13_ then
            return ...
          else
            return error(..., 0)
          end
        end
        local function _46_()
          local config0 = fennel.eval(file:read("*a"))
          local name = path:gsub(".*/", ""):gsub("%.fnl$", "")
          return _G.vim.lsp.config(name, config0)
        end
        local _48_
        do
          local t_47_ = _G
          if (nil ~= t_47_) then
            t_47_ = t_47_.package
          else
          end
          if (nil ~= t_47_) then
            t_47_ = t_47_.loaded
          else
          end
          if (nil ~= t_47_) then
            t_47_ = t_47_.fennel
          else
          end
          _48_ = t_47_
        end
        local or_52_ = _48_ or _G.debug
        if not or_52_ then
          local function _53_()
            return ""
          end
          or_52_ = {traceback = _53_}
        end
        return close_handlers_12_(_G.xpcall(_46_, or_52_.traceback))
      end
      try(_44_)
    end
    return nil
  else
    return nil
  end
end
return {setup = setup, ["do-startup"] = do_startup, dofile = dofile, doStartup = do_startup, ["get-version"] = get_version, getVersion = get_version, ["enable-caching"] = enable_caching, ["disable-caching"] = disable_caching, enableCaching = enable_caching, disableCaching = disable_caching, ["caching-enabled?"] = caching_enabled_3f, isCachingEnabled = caching_enabled_3f, ["get-cache-path"] = get_cache_path, ["get-uncache-path"] = get_uncache_path, getCachePath = get_cache_path, getUncachePath = get_uncache_path, ["get-cache-dir"] = get_cache_dir, getCacheDir = get_cache_dir}
