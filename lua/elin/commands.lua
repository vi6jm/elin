local function fnl(expr, reg)
  local _let_1_ = require("fennel")
  local eval = _let_1_["eval"]
  local view = _let_1_["view"]
  local result = eval(expr)
  if (reg == "") then
    return print(view(result))
  elseif (nil ~= reg) then
    local reg0 = reg
    return vim.fn.setreg(reg0, result)
  else
    return nil
  end
end
local function dofile(file, reg)
  local _let_3_ = require("fennel")
  local dofile0 = _let_3_["dofile"]
  local view = _let_3_["view"]
  local result = dofile0(vim.fs.normalize(file, nil))
  if (reg == "") then
    return print(view(result))
  elseif (nil ~= reg) then
    local reg0 = reg
    return vim.fn.setreg(reg0, result)
  else
    return nil
  end
end
local function dolines(line1, line2, buf, reg)
  local _let_5_ = require("fennel")
  local eval = _let_5_["eval"]
  local view = _let_5_["view"]
  local l1 = (line1 - 1)
  local l2 = line2
  local lines = table.concat(vim.api.nvim_buf_get_lines(buf, l1, l2, true), "\n")
  local result = eval(lines)
  if (reg == "") then
    return print(view(result))
  elseif (nil ~= reg) then
    local reg0 = reg
    return vim.fn.setreg(reg0, result)
  else
    return nil
  end
end
return {fnl = fnl, dofile = dofile, dolines = dolines}
