local P = _G.vim.lpeg["P"]
local R = _G.vim.lpeg["R"]
local S = _G.vim.lpeg["S"]
local C = _G.vim.lpeg["C"]
local Cs = _G.vim.lpeg["Cs"]
local Ct = _G.vim.lpeg["Ct"]
local _5e0
local function _1_(_241)
  return (_241 ^ 0)
end
_5e0 = _1_
local _5e1
local function _2_(_241)
  return (_241 ^ 1)
end
_5e1 = _2_
local _5e_1
local function _3_(_241)
  return (_241 ^ -1)
end
_5e_1 = _3_
local _5e_2
local function _4_(_241)
  return (_241 ^ -2)
end
_5e_2 = _4_
local _5cs = S(" \9")
local _5cs_2a = _5e0(_5cs)
local gt = P(">")
local _2a_2a = C(_5e0(P(1)))
local file
do
  local fname = _5e1((((P("\\") * 1) + P(1)) - S("<>()@ \9")))
  local file_sub
  local function _5_(f)
    local function _6_(_241)
      local _7_ = _241:match("[ \\]")
      if (nil ~= _7_) then
        local s = _7_
        return s
      else
        local _3fs = _7_
        return ("\\" .. _3fs)
      end
    end
    return f:gsub("\\(.)", _6_)
  end
  file_sub = _5_
  file = (_5cs_2a * Cs((fname / file_sub)))
end
local cmd_2a
do
  local to_file
  local function _9_(_241)
    return (_241 == ">")
  end
  to_file = (C(gt) * (_5e_1(gt) / _9_) * ( - gt) * file * _5cs_2a)
  local reg = (R("az", "AZ") + S("\"*+_"))
  local C_gt
  local function _10_(_241)
    return (_241 == ">>")
  end
  C_gt = ((_5e_2(gt) / _10_) * ( - gt) * _5cs_2a)
  local to_reg = (C("@") * C(reg) * C_gt)
  local C_gt0
  local function _11_(_241)
    return (_241 == ">")
  end
  C_gt0 = ((_5e_2(gt) / _11_) * ( - gt) * _5cs_2a)
  local vim_var = (R("az", "AZ") + S("_"))
  local vim_var0 = (vim_var * _5e0((vim_var + R("09"))))
  local to_vim_var = (C("=>") * C_gt0 * C(vim_var0) * _5cs_2a)
  local fnl_var = (R("az", "AZ") + S("_<>!?|^*/-+=%\\"))
  local fnl_var0 = (fnl_var * _5e0((fnl_var + R("09"))))
  local to_fnl_var = (C("->") * C_gt0 * C(fnl_var0) * _5cs_2a)
  local to_put = (C("==") * ( - P("=")) * _5cs_2a)
  local to_all = (to_file + to_reg + to_vim_var + to_fnl_var + to_put)
  cmd_2a = ((Ct((_5cs_2a * to_all)) * _2a_2a) + (Ct("") * _2a_2a))
end
local function werr(msg)
  return _G.vim.api.nvim_echo({{msg}}, true, {err = true, kind = "errormsg"})
end
local function view_result(bang_3f, result)
  local _let_12_ = require("fennel")
  local view = _let_12_["view"]
  local result0 = view(result)
  if bang_3f then
    return result0
  else
    return ("=> " .. result0:gsub("\n", "\n   "))
  end
end
local function handle_matches(bang_3f, matches, result)
  if ((_G.type(matches) == "table") and (matches[1] == "@") and (matches[2] == "_")) then
  elseif ((_G.type(matches) == "table") and (matches[1] == "@") and (nil ~= matches[2]) and (nil ~= matches[3])) then
    local reg = matches[2]
    local a_3f = matches[3]
    local function _14_()
      if a_3f then
        return "a"
      else
        return nil
      end
    end
    _G.vim.fn.setreg(reg, result, _14_())
  elseif ((_G.type(matches) == "table") and (matches[1] == "=>") and (nil ~= matches[2]) and (nil ~= matches[3])) then
    local a_3f = matches[2]
    local name = matches[3]
    local result0
    local _15_
    if a_3f then
      _15_ = _G.vim.g[name]
    else
      _15_ = ""
    end
    result0 = (_15_ .. result)
    _G.vim.g[name] = result0
  elseif ((_G.type(matches) == "table") and (matches[1] == "->") and (nil ~= matches[2]) and (nil ~= matches[3])) then
    local a_3f = matches[2]
    local name = matches[3]
    local _17_
    if a_3f then
      _17_ = _G[name]
    else
      _17_ = ""
    end
    _G[name] = (_17_ .. result)
  elseif ((_G.type(matches) == "table") and (matches[1] == "==")) then
    local line
    if ((_G.vim.api.nvim_buf_line_count(0) == 1) and (_G.vim.api.nvim_buf_get_lines(0, 0, 1, true)[1] == "")) then
      line = 0
    else
      line = (_G.vim.api.nvim_win_get_cursor(0)[1] + 1)
    end
    local line0 = _G.math.min(line, _G.vim.api.nvim_buf_line_count(0))
    local result0
    if bang_3f then
      result0 = ("; " .. result:gsub("\n", "\n; "))
    else
      result0 = result
    end
    _G.vim.api.nvim_buf_set_lines(0, line0, line0, true, result0)
  else
    local _ = matches
    print(view_result(bang_3f, result))
  end
  return nil
end
local function handle(bang_3f, matches, expr)
  local _local_22_ = require("fennel")
  local eval = _local_22_["eval"]
  local _23_, _24_ = nil, nil
  local function _25_()
    return eval(expr, {filename = "stdin", ["error-pinpoint"] = false})
  end
  local function _26_(err)
    werr(err)
    return err
  end
  _23_, _24_ = xpcall(_25_, _26_)
  if ((_23_ == true) and (nil ~= _24_)) then
    local result = _24_
    return handle_matches(bang_3f, matches, result)
  else
    return nil
  end
end
local function do_eval(bang_3f, cmd)
  return handle(bang_3f, cmd_2a:match(cmd))
end
local function do_files(bang_3f, files)
  local expr
  local _28_
  do
    local tbl_21_ = {}
    local i_22_ = 0
    for _, fname in ipairs(files) do
      local val_23_
      do
        local fname0 = _G.vim.fs.normalize(fname)
        local file0 = io.open(fname0, "r")
        local function close_handlers_12_(ok_13_, ...)
          file0:close()
          if ok_13_ then
            return ...
          else
            return error(..., 0)
          end
        end
        local function _30_()
          return (";; " .. fname0 .. "\n" .. file0:read("*a"))
        end
        local _32_
        do
          local t_31_ = _G
          if (nil ~= t_31_) then
            t_31_ = t_31_.package
          else
          end
          if (nil ~= t_31_) then
            t_31_ = t_31_.loaded
          else
          end
          if (nil ~= t_31_) then
            t_31_ = t_31_.fennel
          else
          end
          _32_ = t_31_
        end
        local or_36_ = _32_ or _G.debug
        if not or_36_ then
          local function _37_()
            return ""
          end
          or_36_ = {traceback = _37_}
        end
        val_23_ = close_handlers_12_(_G.xpcall(_30_, or_36_.traceback))
      end
      if (nil ~= val_23_) then
        i_22_ = (i_22_ + 1)
        tbl_21_[i_22_] = val_23_
      else
      end
    end
    _28_ = tbl_21_
  end
  expr = _G.table.concat(_28_, "\n")
  return handle(bang_3f, cmd_2a:match(expr))
end
local function do_lines(bang_3f, line1, line2, _3fbuf, cmd)
  local line10 = (line1 - 1)
  local buf = (_3fbuf or 0)
  local lines = _G.table.concat(_G.vim.api.nvim_buf_get_lines(buf, line10, line2, true), "\n")
  local matches, _ = cmd_2a:match(cmd)
  return handle(bang_3f, matches, lines)
end
local function do_swiss(bang_3f, count, l1, l2, _3fbuf, cmd)
  local files_2a = (Ct(((_5cs_2a * P("<") * _5cs_2a * file) ^ 0)) * _5cs_2a * _2a_2a)
  local files, cmd0 = files_2a:match(cmd)
  local matches, expr = cmd_2a:match(cmd0)
  local files2, expr0 = files_2a:match(expr)
  local files0
  do
    local tbl_19_ = files
    for _, file0 in ipairs(files2) do
      local val_20_ = file0
      table.insert(tbl_19_, val_20_)
    end
    files0 = tbl_19_
  end
  local cat
  local _39_
  do
    local tbl_21_ = {}
    local i_22_ = 0
    for _, fname in ipairs(files0) do
      local val_23_
      do
        local fname0 = _G.vim.fs.normalize(fname)
        local file0 = io.open(fname0, "r")
        local function close_handlers_12_(ok_13_, ...)
          file0:close()
          if ok_13_ then
            return ...
          else
            return error(..., 0)
          end
        end
        local function _41_()
          return (";; " .. fname0 .. "\n" .. file0:read("*a"))
        end
        local _43_
        do
          local t_42_ = _G
          if (nil ~= t_42_) then
            t_42_ = t_42_.package
          else
          end
          if (nil ~= t_42_) then
            t_42_ = t_42_.loaded
          else
          end
          if (nil ~= t_42_) then
            t_42_ = t_42_.fennel
          else
          end
          _43_ = t_42_
        end
        local or_47_ = _43_ or _G.debug
        if not or_47_ then
          local function _48_()
            return ""
          end
          or_47_ = {traceback = _48_}
        end
        val_23_ = close_handlers_12_(_G.xpcall(_41_, or_47_.traceback))
      end
      if (nil ~= val_23_) then
        i_22_ = (i_22_ + 1)
        tbl_21_[i_22_] = val_23_
      else
      end
    end
    _39_ = tbl_21_
  end
  cat = _G.table.concat(_39_, "\n")
  local buf = (_3fbuf or 0)
  local lines
  if (count <= 0) then
    lines = ""
  else
    lines = _G.table.concat(_G.vim.api.nvim_buf_get_lines(buf, (l1 - 1), l2, true), "\n")
  end
  local expr1 = (";; range\n" .. lines .. "\n" .. cat .. "\n\n;; stdin\n" .. expr0)
  return handle(bang_3f, matches, expr1)
end
local function promptCallback(repl, text)
  return coroutine.resume(repl, (text:gsub("\n+$", "") .. "\n"))
end
local function onValues(buf, vals)
  local function _51_()
    if (#vals == 0) then
      return {"nil"}
    else
      local lines = {}
      for _, val in ipairs(vals) do
        local tbl_19_ = lines
        for line in string.gmatch(val, "[^\n]+") do
          local val_20_ = line
          table.insert(tbl_19_, val_20_)
        end
      end
      vim.print(lines)
      return lines
    end
  end
  vim.api.nvim_buf_set_lines(buf, -2, -1, true, _51_())
  return nil
end
local function onError(buf, err)
  vim.api.nvim_buf_set_lines(buf, -2, -1, true, vim.split(err, "\n"))
  return nil
end
local function repl(bang_3f, smods)
  local buf = vim.api.nvim_create_buf(false, true)
  local fennel = require("fennel")
  local _52_
  if _G.jit then
    _52_ = _G.jit.version
  else
    _52_ = ("PUC " .. _VERSION)
  end
  vim.api.nvim_buf_set_lines(buf, -2, -1, true, {("Welcome to Fennel " .. fennel.version .. " on " .. _52_ .. " in Neovim " .. tostring(vim.version()) .. "!")})
  vim.api.nvim_set_option_value("bufhidden", "wipe", {buf = buf})
  vim.api.nvim_set_option_value("buftype", "prompt", {buf = buf})
  vim.api.nvim_buf_set_name(buf, "Fennel REPL")
  vim.fn.prompt_setprompt(buf, ">> ")
  local repl0
  local function _54_(...)
    return fennel.repl(...)
  end
  repl0 = coroutine.create(_54_)
  local function _55_(...)
    return promptCallback(repl0, ...)
  end
  vim.fn.prompt_setcallback(buf, _55_)
  local function _56_(...)
    return onValues(buf, ...)
  end
  local function _57_(_241, _242)
    return onError(buf, _242)
  end
  coroutine.resume(repl0, {readChunk = coroutine.yield, onValues = _56_, onError = _57_, ["error-pinpoint"] = false})
  if bang_3f then
    local w = vim.api.nvim_get_option_value("columns", {})
    local h = vim.api.nvim_get_option_value("lines", {})
    local ww = math.floor((w * 0.8))
    local wh = math.floor((h * 0.8))
    vim.api.nvim_open_win(buf, true, {relative = "editor", width = ww, height = wh, row = math.floor(((h - wh) / 2)), col = math.floor(((w - ww) / 2)), style = "minimal", border = "rounded"})
  else
    vim.cmd.sbuffer({args = {buf}, mods = smods})
  end
  vim.keymap.set("i", "<C-d>", "prompt_getinput(bufnr()) == '' ? '<C-Bslash><C-n>:q!<CR>' : '<C-d>'", {buffer = buf, expr = true})
  vim.keymap.set("i", "<C-l>", "<C-Bslash><C-n>zti", {buffer = buf})
  vim.cmd.startinsert()
  return nil
end
return {["do-eval"] = do_eval, ["do-files"] = do_files, ["do-lines"] = do_lines, ["do-swiss"] = do_swiss, repl = repl}
