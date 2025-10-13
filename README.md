
# elin

*Extensible Lisp Integration for Neovim*

**v0.0.6**

**Requirements:** Neovim +v0.8.0


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

With a package manager, just install it into `&rtp` however. It uses
`&rtp/plugin/startup.lua` to bootstrap itself.


## Elin Module

**Note:** Elin adheres to the `fennel-style-guide` but provides camel-case
equivalents for ease of use in lua. Examples:
- `(get-version)` -> `getVersion()`
- `caching-enabled?)` -> `isCachingEnabled()`


### happy path

This is all I do, and I am happy; therefore, this will work for you, too:

```fennel
;; init.fnl
(_G.vim.loader.enable)                      ;; enable .lua caching
(let [{: enable-caching : dofile} (require :elin)
      config (_G.vim.fn.stdpath :config)]
  (enable-caching)                          ;; enable .fnl caching
  (dofile (.. config :/fnl/pack/init.fnl))) ;; load plugin config
nil
```

This enables `vim.loader` and elin caching to speed up neovim startup by over
100ms (for me). Then, I early load my plugin configuration at
{config}/fnl/pack/init.fnl. The rest of my configuration is in `plugin.fnl`,
`ftplugin.fnl`, etc files. See `elin-config` for more information.


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



### setup

`(elin.setup {opts})`

Change how elin behaves. Defaults:

```fennel
(let [{: setup} (require :elin)]
    (setup {:enable-caching false
            :cache-dir (.. (vim.fn.stdpath :cache) :elin)}))
```

- **Parameters:** `{opts}?` (`table?`) Options for customizing elin behavior:
    - `{enable-caching}` (`boolean?`, default: `false`) enables caching for
      fennel modules loaded via `require()` and `(elin.dofile)`. This is the
      same as invoking `(elin.enable-caching)`.
    - `{cache-dir}` (`string?`, default: `(vim.fn.stdpath :config) .. :elin)`)
      directory where elin stores its cached `.luac` files.

**Note:** Elin is intended to be a drop-in fennel bootstrapper. Therefore,
there is not much to customize (yet?). If you want something to be more
flexible, don't hestitate to open an issue or notify the maintainer.


### do-startup

`(elin.do-startup {opts})`

This attempts to source `init.fnl` (unless `init.lua` or `init.vim` exists and
{do-init-fnl} is not `true`) and then sources every `plugin.fnl`.

This is called implicitly during `startup` when `elin/plugin/startup.lua` is
loaded, but it can be called earlier during `init.lua` if desired. It guards
itself against repetitive invocations unless {force} is `true`.

- **Parameters:** {opts}? (`table?`) Options for `do-startup`:
    - `{do-init-fnl}?` (`boolean`, default: `false`) source `init.fnl` even if
      `init.lua` or `init.vim` are detected.
    - `{force}?` (`boolean?`, default: `false`) do startup even if it was
      already done.


### dofile

`(elin.dofile {path} {opts})`

With caching enabled, use cache to load byte-compiled code associated with
`{path}`. Otherwise, this is the same as `(fennel.dofile {opts})`.

When the cached file doesn't exist or has an `mtime` older than the file at
{path}, load {path} with `(fennel.dofile)` and store its luajit byte code into
the cache path, which can be found with `(elin.get-cache-path {path})`.

- **Parameters:** `{opts}?` (`table`) Options passed to `(fennel.dofile)`.

- **Return:** (`any`) The result of the loaded file or byte code


### get-version

`(elin.get-version)`
  Get elin's version in the format `"v{major}.{minor}.{patch}"`. The current
  version is `v0.0.6`.

- **Return:** (`string`) The version


### enable- and disable-caching

`(elin.enable-caching)` / `(elin.disable-caching)`

This is similar to neovim's experimental `vim.loader`, but it caches fennel to
luajit byte code instead of lua.

- Enable:
    - uses a loader so that `require()` on `.fnl` files uses cached byte code
    - `(elin.dofile)` also uses the byte-compilation cache

- Disable:
    - removes the loader
    - `(elin.dofile)` uses `(fennel.dofile)` always


### caching-enabled?

`(elin.caching-enabled?)`

Check if caching was enabled via `(elin.enable-caching)`

- **Return:** (`boolean`) Caching enabled?


### get-cache- and get-uncache-path

`(elin.get-cache-path {path})` / `(elin.get-uncache-path {cpath})`

Get a file's cache path from an absolute {path} or get the uncached path from
{cpath}. These are complementary functions that reverse the other.

Example:

```fennel
(local elin (require :elin))
(print (elin.get-cache-path "/home/me/foo.fnl"))
;; => "/home/me/.cache/nvim/elin/%2fhome%2fme%2ffoo%2efnl.luac"
(print (elin.get-uncache-path
"/home/me/.cache/nvim/elin/%2fhome%2fme%2ffoo%2efnl.luac"))
;; => "/home/me/foo.fnl"
```

- **Parameters:** {path} or {cpath} (`string`) path or cached path to turn into
  the other

- **Return:** (`string`) The cached or uncached path


### get-cache-dir

`(elin.get-cache-dir)`

Get the directory where `.luac` (luajit byte code) files are stored. This can be
changed with `(elin.setup)`. `(elin.get-cache-path)` also references this
setting.

- **Return:** (`string`, default: `(.. (vim.fn.stdpath :cache) :elin)`) Elin's
  cache directory.


## Configuration

INIT:
- `{config}/init.fnl`
- `{config}/plugin/**/*.fnl`
- `{config}/after/plugin/**/*.fnl`
- `{config}/lsp/*.fnl`

Before filetype plugins:
- `b:undo_ftplugin_fnl` `(string|function)` fennel string (or function)
- `b:undo_ftplugin_lua` `(string|function)` lua string (or function)

filetype plugins:
- `{config}/ftplugin/*.fnl`
- `{config}/after/ftplugin/*.fnl`
- `{config}/syntax/*.fnl`
- `{config}/after/syntax/*.fnl`

In noevim, use `:help elin-config` for more information.

## Commands

- `:Fnl [{redir}] {expr} [{expr} ...]`
- `:FnlFiles [{redir}] {file} [{file} ...]`
- `:[range]FnlLines [{redir}]`
- `:[range]FnlSwiss  [{redir}] ...] [{expr} ...]`


### Commands Redir

Above, `{redir}` is optional and means that each command can use special syntax
to redirect the *result* of the fennel evaluation to various places.

| `{redir}` | Description |
| --- | --- |
| `> {file}` | write *result* to file `{file}` |
| `@a`, `@a>` | save *result* to register `@a` |
| `@A`, `@a>>` | append *result* to register `@a` |
| `@+`, `@*`, `@"` | save *result* to PRIMARY, SELECT, or `@"` (resp.) |
| `@+>`, `@*>`, `@">` | (same as above) |
| `@+>>`, `@*>>`, `@">>` | same as above but append to register |
| `=> {var}` | save *result* to vim variable `g:{var}` |
| `=>> {var}` | append *result* to vim variable `g:{var}` |
| `-> {var}` | save *result* to lua variable `_G.{var}` |
| `->> {var}` | append *result* to lua variable `_G.{var}` |
| `@_` | store *result* in black hole register (print nothing, do nothing) |
| `==` | `:put` *result* on new line |


### Fennel Swiss

`:FnlSwiss` is all three other commands merged into one Swiss army knife. It
supports `[range]` like `:FnlLines` and `[{expr} ...]` like `:Fnl`, but to
support files, as well, it uses a special `{redir}`-like syntax, which can be
before, after, or both before and after `{redir}` (if provided).

If any are specified, FnlSwiss evaluates the `[range]` first, then all
`{file}`s, and finally any `{expr}`s.

For more information, see `:help elin-commands` in neovim.


## Maintainer

```
         oo   .8P  oo             |
         ''  88'   ''            -*-                  You can call me Vi!
  dP  dP dP d8baa. dP 88d8b.d8b.  |                   ✓ That's vai /vī/ ✓
  d8 d8' 88 88''88 88 88''88''88                      ∅ Not vee /vē/ ∅
  d8d8'  88 8b..d8 88 88  88  88          |
  d8P'   dP 'Y88P' 88 dP  dP  dP         -*-          Here's my email!
                   88             dP      |           _@_._
   .d88b.         dP              88
  d8'  '88  .8d8b. .8d88 .d88b. d8888P .d88b. 88d8b.         |
  88 d8.88  88''88 88'   88''88   88   88''88 88''88        -*-
  88 Yo8P'  88..88 88    88..88   88   88..88 88  88         |
  Y8.   ..  8Y8P'  dP    'Y88P'   dP   '888P' dP  dP
   'Y888P'  88
            dP  88d8b.d8b. .d88b.
                88''88''88 88ood8       |             If you can't read it,
            dP  88  88  88 88. ..      -*-            send me an email, and
            88  dP  dP  dP '888P'       |             I'll email it to you.
```


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

- [ ] create `elin.init()` that can be called from `init.lua`, call from
  `plugin/startup.lua`, as well. Keep guard.
  - allow higher priority during INIT (if user wants to disable builtin plugins)
- [ ] repl using buftype=prompt
- [ ] sanity macros to fix vim + vimL <- nvim + lua <- fennel pipeline nightmare
- [ ] a separate package manager integrating with pack + elin
- [ ] :checkhealth
- [ ] better edge case handling for :Fnl commands
