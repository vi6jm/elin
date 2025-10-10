elin
====

*Extensible Lisp Integration for Neovim*

**v0.0.6**

**Requirements:** Neovim +v0.8.0


About
-----

Elin enhances neovim with seamless fennel configuration. Just write `.fnl`
files where you would normally write `.lua` or `.vim` files. For more info,
see [Configuration](#Configuration).

Fennel is a lisp that compiles directly to lua or evaluates fennel using a lua
interpreter. Elin uses neovim's luajit to bootstrap fennel on top and
tries to make it as comfortable to use `.fnl` files as it is to use `.lua`
files everywhere.

There are also some nice commands for evaluating fennel in various ways. Check
out [Commands](#Commands)

For your convenience, some reference help documents, with the good graces of
the fennel maintainers, are ported and distributed with this plugin. In neovim,
use `:help elin-fennel-toc` to see the list of ported help docs.


Installation
------------

No lua required:

```bash
cd .config/nvim;
# export elin='https://git.sr.ht/~vi6jm/elin';
git clone $elin pack/local/start/elin;
```

With a package manager, just install it into `&rtp` however. It uses
`&rtp/plugin/` to bootstrap itself.


Elin Module
-----------

**Note:** as demonstrated below, the elin module has both functions that are
easy to use in lua as well as names that adhere to the *fennel style guide*.

### setup

Elin intends to be a drop-in bootstrapper for fennel, but the defaults may not
be what you want. In this case, you can require the elin module and use its
`.setup()` to better suit your preferences:

```fennel
;; init.fnl
(vim.loader.enable) ;; call before (fennel.enable-caching)
(let [{: setup : enable-caching} (require :elin)]
  (setup {:cache-dir :/tmp/elin-cache/})
  (enable-caching))
```

```lua
-- init.lua (alternative)
local elin = require("elin")
elin.setup { cacheDir = "/tmp/elin-cache/" }
vim.loader.enable()
elin.enableCaching()
```
At the moment, there isn't much to tweak: only `cache-dir` (alternatively,
`cacheDir`). This is easily remedied; don't hesitate to submit an issue if you
want something to be more customizable.

### get version

Use these functions to get elin's version in the format
`v{major}.{minor}.{patch}`. The current version is `v0.0.6`.

```fennel
;; init.fnl
(let [{: get-version} (require :elin)]
  (print "Elin version:" (get-version)))
;; => Elin version: v0.0.6
```

```lua
-- init.lua (alternative)
local elin = require("elin")
print("Elin version:", elin.getVersion())
-- => Elin version: v0.0.6
```

### loader

Elin can inject a package loader that will automatically cache fennel modules
when required, so that neovim initializes faster. It does this by storing
luajit byte code in `stdpath("cache") .. "/elin/"`. This is considered
experimental, so you have enable the loader manually.

You can also pair this with neovim's experimental loader, `vim.loader`. I'm
seeing 70ms speedup using both.

#### enable-caching

**Note:** Be sure that you enable vim's loader before elin's loader.

```fennel
;; init.fnl
(vim.loader.enable) ;; enable before (enable-loader) or not at all
(let [{: enable-caching : caching-enabled?} (require :elin)]
  (enable-caching)
  (print "Elin caching is enabled?" (caching-enabled?)))
  ;; => Elin caching is enabled? true
```

### utilities

Elin also exposes functions it uses internally to manage plugins, filetype
plugins, the caching loader, etc. Feel free to use them where needed.

#### dofile

This respects the [loader](#loader). If not enabled, then it simply calls
`(fennel.dofile)`.

```fennel
;; plugin/snippets.fnl
(local get-rtp-file _G.vim.api.nvim_get_runtime_file)
(fn activate-snippets []
  "source &rtp/snippets/activate.fnl"
  (case (. (get-rtp-file :snippets/activate.fnl false) 1)
    snip-activ-path (let [{: dofile}] (require :eline)
                      (dofile snip-activ-path))
    _ (print "Fatal: Unable to find &rtp/snippets/activate.fnl")))
```

#### cache-/uncache-path and cache dir

When [the loader](#loader) is enabled, it uses `get-cache-path` to turn an
absolute path into an encoded path in the `cache dir`. Remember, you can set the
`cache dir` with [`(elin.setup)`](#setup). If you need to, you can also find the
absolute path of a cached file path using `get-uncache-path`:

```fennel
;; plugin/test.fnl
(let [some-path (.. (vim.fn.stdpath :config) :/some/file.fnl)
      {: setup
       : get-cache-path
       : get-uncache-path
       : get-cache-dir} (:require elin)]
  (setup {:cache-dir (.. (vim.fn.stdpath :cache) :foo))
  (print (get-cache-dir))
  (print (get-cache-path some-path))
  (print (get-uncache-path (get-cache-path some-path))))
;; stdout:
; /home/me/.cache/nvim/foo/
; /home/me/.cache/foo/%2fhome%2fme%2f%2econfig%2fnvim%2fsome%2ffile%2efnl.luac
; /home/me/.config/nvim/some/file.fnl
```

Configuration
-------------

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

Commands
--------

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

Thanks
------
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

Todo
----

- [ ] create `elin.init()` that can be called from `init.lua`, call from
  `plugin/startup.lua`, as well. Keep guard.
  - allow higher priority during INIT (if user wants to disable builtin plugins)
- [ ] repl using buftype=prompt
- [ ] sanity macros to fix vim + vimL <- nvim + lua <- fennel pipeline nightmare
- [ ] a separate package manager integrating with pack + elin
- [ ] :checkhealth
- [ ] better edge case handling for :Fnl commands
