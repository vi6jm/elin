local version = "v0.0.6"
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
vim.fn.mkdir(cache_dir, "p")
local function setup(opts)
  local cd = (opts["cache-dir"] or opts.cacheDir)
  if (type(cd) == "string") then
    cache_dir = (cd:gsub("/+$", "") .. "/")
    return nil
  else
    return nil
  end
end
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
  local function _3_(_241)
    return string.format("%%%x", string.byte(_241))
  end
  cpath = path:gsub("%A", _3_)
  return (cache_dir .. cpath .. ".luac")
end
local function get_uncache_path(cpath)
  local path = cpath:gsub("%.luac?$", "")
  local function _4_(_241)
    return string.char(tonumber(_241, 16))
  end
  return path:gsub(".*/", ""):gsub("%.luac?$"):gsub("%%(%x%x)", _4_)
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
  local function _6_()
    local _let_7_ = require("fennel")
    local compile = _let_7_["compile"]
    local traceback = _let_7_["traceback"]
    local _8_, _9_ = nil, nil
    local function _10_()
      return compile(fh, (_3fopts or {filename = path, correlate = true}))
    end
    local function _11_(err)
      werr(traceback(err))
      return err
    end
    _8_, _9_ = xpcall(_10_, _11_)
    if ((_8_ == true) and (nil ~= _9_)) then
      local code = _9_
      local fh0 = fs_open(cpath, "w", 438)
      local f = _G.loadstring(code)
      fs_write(fh0, string.dump(f, true))
      fs_close(fh0)
      return f
    elseif (true and (nil ~= _9_)) then
      local _ = _8_
      local err = _9_
      return nil, err
    else
      return nil
    end
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
  return close_handlers_12_(_G.xpcall(_6_, or_18_.traceback))
end
local function dofile_cached(path, _3fopts)
  local cpath = get_cache_path(path)
  local cstat = fs_stat(cpath)
  local stat = fs_stat(path)
  local _20_
  if ((cstat == nil) or (cstat.mtime.sec < stat.mtime.sec) or (cstat.mtime.nsec < stat.mtime.nsec)) then
    _20_ = write_cache(path, cpath, _3fopts)
  else
    _20_ = _G.loadstring(readfile(cpath, 438))
  end
  if (nil ~= _20_) then
    local f = _20_
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
  local _24_ = get_rtp_file(("fnl/" .. mod0 .. ".fnl" .. " fnl/" .. mod0 .. "/init.fnl"), false)[1]
  if (nil ~= _24_) then
    local path = _24_
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
return {setup = setup, ["get-version"] = get_version, getVersion = get_version, ["enable-caching"] = enable_caching, ["disable-caching"] = disable_caching, enableCaching = enable_caching, disableCaching = disable_caching, ["caching-enabled?"] = caching_enabled_3f, isCachingEnabled = caching_enabled_3f, dofile = dofile, ["get-cache-path"] = get_cache_path, ["get-uncache-path"] = get_uncache_path, getCachePath = get_cache_path, getUncachePath = get_uncache_path, ["get-cache-dir"] = get_cache_dir, getCacheDir = get_cache_dir}
