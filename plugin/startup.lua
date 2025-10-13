if _G["_elin-did-startup"] then
  return
else
end
_G["_elin-did-startup"] = true
local elin = require("elin")
elin["do-startup"]()
do
  local cmd = _G.vim.api.nvim_create_user_command
  local function _2_(ev)
    local _let_3_ = require("elin.commands")
    local do_eval = _let_3_["do-eval"]
    do_eval(ev.bang, ev.args)
    return nil
  end
  cmd("Fnl", _2_, {nargs = "+", bang = true, desc = "fennel.eval {expression} to wherever"})
  local function _4_(ev)
    local _let_5_ = require("elin.commands")
    local do_files = _let_5_["do-files"]
    do_files(ev.bang, ev.fargs)
    return nil
  end
  cmd("FnlFiles", _4_, {nargs = "+", bang = true, complete = "file", desc = "fennel.eval files"})
  local function _6_(ev)
    local _let_7_ = require("elin.commands")
    local do_lines = _let_7_["do-lines"]
    do_lines(ev.bang, ev.line1, ev.line2, 0, ev.args)
    return nil
  end
  cmd("FnlLines", _6_, {nargs = "*", bang = true, range = "%", desc = "fennel.eval range"})
  local function _8_(ev)
    local _let_9_ = require("elin.commands")
    local do_swiss = _let_9_["do-swiss"]
    do_swiss(ev.bang, ev.count, ev.line1, ev.line2, 0, ev.args)
    return nil
  end
  cmd("FnlSwiss", _8_, {nargs = "*", bang = true, range = true, desc = "fennel.eval(<files [range] {expression}) to wherever"})
end
do
  local aug = _G.vim.api.nvim_create_augroup("elin", {})
  local au = _G.vim.api.nvim_create_autocmd
  local function _10_(_241)
    local _let_11_ = require("elin.ftplugin")
    local do_filetype_plugins = _let_11_["do-filetype-plugins"]
    return do_filetype_plugins(_241)
  end
  au("FileType", {group = aug, callback = _10_, desc = "load fennel files"})
  local function _12_(ev)
    elin.dofile(_G.vim.fs.normalize(ev.file, nil))
    return nil
  end
  au("SourceCmd", {group = aug, pattern = "*.fnl", callback = _12_, desc = ":source fennel files"})
end
return nil
