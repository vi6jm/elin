elin
====
*Extensible Lisp Integration for Neovim*

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

Installation
------------

No lua required:

```sh
cd .config/nvim;
# export elin='https://git.sr.ht/~vi6jm/elin';
git clone $elin pack/local/start/elin;
```


With a package manager, just install it into `&rtp` however. It uses
`&rtp/plugin/` to bootstrap itself.

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

### Example Commands

```vim
" say hi; store "bar" into vim.g.foo
:Fnl => foo (print "hello from fennel") "bar"
" evaluate paragraph with fennel and put on next line commented
:'{,'}FnlLines ==
" evaluate ~/fennel-test.fnl into @+ register
:FnlFiles @+ ~/fennel-test.fnl 
" eval from line to end of buffer and file ~/utils.fnl; store 9 into _G.Res
:.,$FnlSwiss -> Res < ~/utils.fnl (sum 2 3 4)

**Note:** :Fnl\* commands gobble `bar` like commands listed in `:help :bar`
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
- [~gpanders nvim-moonwalk (github)](https://github.com/gpanders/nvim-moonwalk)
- [~alexaandru fennel-nvim (github)](https://github.com/alexaandru/fennel-nvim)
- [~udayvir-singh tangerine.nvim (github)](https://github.com/udayvir-singh/tangerine.nvim)

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

Todo
----
- [ ] options: `cache-on-write-fnl`, `cache-on-load-fnl` (defaulting to true)
- [ ] `cache-on-write`: cache fnl -> lua when write fnl in config dir.
- [ ] `cache-on-load`: package.loader that knows how to cache fnl -> lua
  - can be own loader before fnl loader OR conditional inside fnl loader
  - basically have to rewrite `:help vim.loader`
    - that's fine, we want to cache anyway ig; draw wisdom from neovim!
- [ ] repl using buftype=prompt
- [ ] sanity macros to fix vim + vimL <- neovim + lua <- fennel pipeline nightmare
- [ ] a separate package manager integrating with pack + elin
- [ ] :checkhealth
- [ ] edge cases for :Fnl commands
- [ ] better instead of `:Fnl` with `[!]`, parse own directives and `[!]` can
      be like `:redir` `[!]`.
