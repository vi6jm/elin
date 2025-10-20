
# elin

> *Extensible Lisp Integration for Neovim*
> **v0.0.8**
> for neovim +v0.8.0


## About

Elin enhances neovim with seamless fennel configuration. Just write `.fnl` files
where you would normally write `.lua` or `.vim` files. For more info, see
[Configuration](#Configuration).

Fennel is a lisp that compiles directly to lua or evaluates fennel using a lua
interpreter. Elin uses neovim's luajit to bootstrap fennel on top and tries to
make it as comfortable to use `.fnl` files as it is to use `.lua` files
everywhere.

There are also some nice commands for evaluating fennel in various ways. Check
out [Commands](#Commands)

For your convenience, some reference help documents, with the good graces of the
fennel maintainers, are ported and distributed with this plugin. In neovim, use
`:help elin-fennel-toc` to see the list of ported help docs.


## Installation

No lua required:

```bash
export elin='https://git.sr.ht/~vi6jm/elin';
cd ~/.config/nvim;
git clone $elin pack/local/start/elin;
```

Or install it noramlly with package manager (it uses `&rtp/plugin/startup.lua`
to bootstrap itself).


## Elin Module

**Note:** Elin adheres to the `fennel-style-guide` but provides camel-case
equivalents for ease of use in lua. Examples:
- `(elin.get-version)` -> `elin.getVersion()`
- `(elin.caching-enabled?)` -> `elin.isCachingEnabled()`


### happy path

This is all I do, and I am happy; therefore, this will make you happy, too:

```fennel
;; init.fnl
(let [{:enable nvim-cache} _G.vim.loader
      {:enable-caching elin-cache} (require :elin)
      {:setup bp-setup (require :backpack)]
  (nvim-cache) ;; enable .lua caching
  (elin-cache) ;; enable .fnl caching
  (bp-setup))  ;; set up pack plugins
nil
```

Just kidding. See the rest of the help to learn how elin can better suit your
wants and needs for using fennel for neovim config.


### startup

Elin bootstraps itself with {elin}/plugin/startup.lua. This calls
`(elin.do-startup)`, which will try to load `init.fnl` and then all `plugin.fnl`
files.


### init.lua

If you want to use `init.lua` as your entry point instead (it has a higher
priority and is loaded before plugins like `gzip`, etc), you can! Just use
something like the following:

```lua
-- init.lua
vim.loader.enable() -- optional
local elin = require("elin")
elin.enableCaching() -- optional
elin.doStartup { loadInitFnl = true }
```

```fennel
;; init.fnl
(set vim.g.loaded_gzip 1) ;; disable builtin gzip plugin
;; this won't work unless you load init.fnl early with above init.lua!
```

Now just add `.fnl` files to `plugin/`, `ftplugin/`, etc. (see `elin-config`)!



### module methods

- `(elin.setup {opts})`: change how elin behaves
  - with `enable-caching = true` in opts, enable caching
  - with `cache-dir = "path"` in opts, change where cached files are stored
- `(elin.do-startup {opts})`: source `init.fnl` and every `plugin.fnl`
    - with `do-init-fnl = true` in opts, load `init.fnl` even if an `init.lua`
      is detected
    - with `force = true` in opts, do startup even if it was already executed
- `(elin.dofile {path} {opts})`: like `fennel.dofile()` but respect caching.
- `(elin.get-version)`: get version; current version: `v0.0.8`
- `(elin.enable-caching)`: enable caching; similar to `vim.loader`
- `(elin.disable-caching)`: disable caching
- `(elin.caching-enabled?)`: true if caching enabled; else false
- `(elin.get-cache-path {path})`: get cache path for path
- `(elin.get-uncache-path {cpath})`: get path from cache path
- `(elin.get-cache-dir)`: get cache dir (can be changed in `(elin.setup)`

See `:help elin-module` in neovim for more complete documentation.


## Configuration

Startup:
- `{config}/init.fnl`
- `{config}/plugin/**/*.fnl`
- `{config}/after/plugin/**/*.fnl`
- `{config}/lsp/*.fnl`

Before filetype plugins (like `b:undo_ftplugin` but for fennel/lua):
- `b:undo_ftplugin_fnl` fennel expression / function
- `b:undo_ftplugin_lua` lua expression / function

Filetype plugins:
- `{config}/ftplugin/*.fnl`
- `{config}/after/ftplugin/*.fnl`
- `{config}/syntax/*.fnl`
- `{config}/after/syntax/*.fnl`

Use `:help elin-config` for more information.


## Commands

- `:Fnl [{redir}] {expr} [{expr} ...]`
- `:FnlFiles [{redir}] {file} [{file} ...]`
- `:[range]FnlLines [{redir}]`
- `:[range]FnlSwiss  [{redir}] ...] [{expr} ...]`

`{redir}` is optional and means that each command can use special syntax to
redirect the *result* of the fennel evaluation to various places:

| `{redir}`  | Description |
| -------- | ----------- |
| `> {file}` | write *result* to file `{file}` <sup>\[1\]</sup> |
| `< {file}` | include `{file}` in evaluated expression <sup>\[2\]</sup> |
| `@a>`      | save *result* to `@a` <sup>\[1\] \[2\] \[3\] |
| `=> {var}` | save *result* to vim variable `g:{var}` <sup>\[1\]</sup> |
| `-> {var}` | save *result* to lua variable `_G.{var}` <sup>\[1\]</sup> |
| `==`       | `:put` *result* on new line |

- <sup>\[1\]</sup> replace `>` with `>>` to append instead of overwrite
- <sup>\[2\]</sup> `:FnlSwiss` only
- <sup>\[3\]</sup> `@+`, `@*`, `@"`, `@_` also supported

`:FnlSwiss` is the "swiss army knife" that combines the other three into one
command. Use `< {file}` in `{redir}` to read in a file and evaluate it. Example

```vim
:'{,'}FnlSwiss <input.fnl >output.fnl (.. :the :- :end)
```

- `:FnlRepl[!]`

See `:help elin-commands`.


## Thanks

A special thanks to the fennel contributors and hotpot.nvim for the hard work
necessary to make this project viable and inspiration. Thanks also to fennel-ls
and fennel-ls-nvim-docs.

- [fennel-lang.org](https://fennel-lang.org/)
- [dev.fennel-lang.org/wiki](https://dev.fennel-lang.org/wiki/WikiStart)
- [~xerool fennel-ls (sr.ht)](https://git.sr.ht/~xerool/fennel-ls)
- [~rktjmp hotpot.nvim (github)](https://github.com/rktjmp/hotpot.nvim)
- [~micampe fennel-ls-nvim-docs (sr.ht)](https://git.sr.ht/~micampe/fennel-ls-nvim-docs)

Thanks also to other projects that bring fennel into neovim. You all make the
fennel ecosystem a little brighter.

- [~Olical nfnl (github)](https://github.com/Olical/nfnl)
- [~Olical aniseed (github)](https://github.com/Olical/aniseed)
- [~jaawerth fennel.vim (github)](https://github.com/jaawerth/fennel.vim)
- [~jaawerth fennel-nvim (github)](https://github.com/jaawerth/fennel-nvim)
- [~gpanders nvim-moonwalk (github)](https://github.com/gpanders/nvim-moonwalk)
- [~alexaandru fennel-nvim (github)](https://github.com/alexaandru/fennel-nvim)
- [~udayvir-singh tangerine.nvim (github)](https://github.com/udayvir-singh/tangerine.nvim)

---

```
                                 |
                                -*-
                                 |                 |
                                  ,dPb,    |      -*-
                                  IP"Yb   -*-      |
                         |        I8 8P gg |
                        -*-       db 8I ""             |
                         |  ,gg,  d8 8" gg  ,gg, ,gg  -*-
                           i8" 8i I8dP  88 ,8PY8YP"g8, |
                           8I ,8I I8P   d8 I8  8I   8i
                    |    _,Igd8P,,d8b,_,88,dP  8I   "8,    |
                   -*-  888P""Y888P'"Y8P""8P'  8I  | "8i  -*-
                    |            |                -*-      |
                                -*-                |
                                 |
```

## Todo

- [ ] `:checkhealth`
- [ ] sanity macros to fix vim + vimL <- nvim + lua <- fennel pipeline nightmare
- [ ] `.elin.fnl` (or other root marker) to determine where/how to AOT compile
  on bufwrite
- [ ] docstrings \[-> readme/vimdoc?\]
- [ ] better edge case handling for :Fnl commands
- [ ] a separate package manager integrating with pack + elin

