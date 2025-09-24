elin
====
*Extensible Lisp Integration for Neovim*

**About:** elin enhances nvim with seamless fennel configuration
**Requirements:** +v0.8.0
**Installation:** `cd .config/nvim; git clone $elin pack/local/start/elin` etc

About
-----

Elin enhances neovim with seamless fennel configuration. Just write `.fnl`
files where you would normally write `.lua` or `.vim` functions. For more
information, see |elin-config|.

Fennel is a lisp that compiles directly to lua or evaluates fennel using a lua
interpretter. Elin uses neovim's |lua-luajit| to bootstrap fennel on top and
tries to make it as comfortable to use `.fnl` files as it is to use `.lua`
files everywhere.

There are also some nice commands for evaluating fennel in various ways. Check
out |fennel-commands|.

See |elin-api.txt| for elin's api used in |compile-nvim|.

Better features coming soon!
- [ ] support "." in 'filetype' during ftplugin
- [ ] cache on write (also check timestamps at \<insert time\> (init? ftplugin?)?)
- [ ] find+remember cached elin-rtp files and don't duplicate during INIT/ftplugin
    - use "strategy" (change in .setup). see strategies below:
    - "fennel-cache": only load cached lua files if there is a corresponding
      fennel file in &rtp; cache if timestamp is old(?)
    - "cache-only": only load cached lua files. new fennel files are cached.
    - "fennel-only": only load fennel files in config. ignore cache.
    - "all": load all fennel and lua files (without duplicates). do not cache.
    - "lua-only": ignore all fennnel files. most of this plugin becomes
      irrelevant.
- [ ] sanity macros to fix vim + vimL <- neovim + lua <- fennel pipeline nightmare
- [ ] a separate package manager integrating with |pack| + |elin| w lazy loading
- [ ] etc!

Commands
--------

| Command | Description |
|---------|-------------|
| `:Fnl [x] {expr}`           | Evaluate {expr} \[into register x\]    |
| `:FnlDofile {file}`         | Evaluate {file}                        |
| `:FnlDofileReg [x] {file}`  | Evaluate {file} \[into register x\] *  |
| `:[range]FnlDolines [x]`    | Evaluate \[range\] \[into register x\] |

\* Warning: This will (almost always) eat the first letter of `{file}` unless you pass a
register, since files generaly don't start with "(" or another character vim
does not treat as a register! The other cmomands are not issues because they
either must start with a "(" to be a valid fennel expression or do not accept
arguments.

Configuration
-------------

INIT:
- `{config}/init.fnl`
- `{config}/plugin/**/*.fnl`
- `{config}/after/plugin/**/*.fnl`
- `{config}/lsp/*.fnl`

before filetype plugins:
- `b:undo_ftplugin_fnl` `(string|function)` fennel string (or function)
- `b:undo_ftplugin_lua` `(string|function)` lua string (or function)

filetype plugins:
- `{config}/ftplugin/*.fnl`
- `{config}/after/ftplugin/*.fnl`
- `{config}/syntax/*.fnl`
- `{config}/after/syntax/*.fnl`

Thanks
------
A special thanks to the fennel contributers and hotpot.nvim for the hard work
necessary to make this project viable and inspiration. Thanks also to
fennel-ls and fennel-ls-nvim-docs.

[fennel-lang.org](https://fennel-lang.org/)
[dev.fennel-lang.org/wiki](https://dev.fennel-lang.org/wiki/WikiStart)
[~xerool fennel-ls (sr.ht)](https://git.sr.ht/~xerool/fennel-ls)
[~rktjmp hotpot.nvim (github)](https://github.com/rktjmp/hotpot.nvim)
[~micampe fennel-ls-nvim-docs (sr.ht)](https://git.sr.ht/~micampe/fennel-ls-nvim-docs)

Thanks also to other projects that bring fennel into neovim. You all make the
fennel ecosystem a little brighter.

[~Olical aniseed (github)](https://github.com/Olical/aniseed)
[~gpanders nvim-moonwalk (github)](https://github.com/gpanders/nvim-moonwalk)
[~alexaandru fennel-nvim (github)](https://github.com/alexaandru/fennel-nvim)
[~udayvir-singh tangerine.nvim (github)](https://github.com/udayvir-singh/tangerine.nvim)

```
                                |
                         |     -*-
                        -*-     |
                         |                            |
  |                                                  -*-
 -*-                                                  |
  |                                           |
       |                                     -*-
      -*-                                     |                  |
       |                                                        -*-
                                                                 |
```
