local elin = require("elin")
elin["do-startup"]()
do
  local cmd = _G.vim.api.nvim_create_user_command
  local function _1_(_241)
    local _let_2_ = require("elin.commands")
    local do_eval = _let_2_["do-eval"]
    do_eval(_241.bang, _241.args)
    return nil
  end
  cmd("Fnl", _1_, {nargs = "+", bang = true, desc = "fennel.eval {expression} to wherever"})
  local function _3_(_241)
    local _let_4_ = require("elin.commands")
    local do_files = _let_4_["do-files"]
    do_files(_241.bang, _241.fargs)
    return nil
  end
  cmd("FnlFiles", _3_, {nargs = "+", bang = true, complete = "file", desc = "fennel.eval files"})
  local function _5_(_241)
    local _let_6_ = require("elin.commands")
    local do_lines = _let_6_["do-lines"]
    do_lines(_241.bang, _241.line1, _241.line2, 0, _241.args)
    return nil
  end
  cmd("FnlLines", _5_, {nargs = "*", bang = true, range = "%", desc = "fennel.eval range"})
  local function _7_(_241)
    local _let_8_ = require("elin.commands")
    local do_swiss = _let_8_["do-swiss"]
    do_swiss(_241.bang, _241.count, _241.line1, _241.line2, 0, _241.args)
    return nil
  end
  cmd("FnlSwiss", _7_, {nargs = "*", bang = true, range = true, desc = "fennel.eval (<files [range] {expression}) to wherever"})
  local function _9_(_241)
    local _let_10_ = require("elin.commands")
    local repl = _let_10_.repl
    repl(_241.bang, _241.smods)
    return nil
  end
  cmd("FnlRepl", _9_, {nargs = 0, bang = true, bar = true, desc = "fennel repl"})
end
do
  local aug = _G.vim.api.nvim_create_augroup("elin", {})
  local au = _G.vim.api.nvim_create_autocmd
  local function _11_(_241)
    local _let_12_ = require("elin.ftplugin")
    local do_filetype_plugins = _let_12_["do-filetype-plugins"]
    return do_filetype_plugins(_241)
  end
  au("FileType", {group = aug, callback = _11_, desc = "load fennel files"})
  local function _13_(ev)
    elin.dofile(_G.vim.fs.normalize(ev.file, nil))
    return nil
  end
  au("SourceCmd", {group = aug, pattern = "*.fnl", callback = _13_, desc = ":source fennel files"})
end
return nil
