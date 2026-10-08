# Regression checks

Requires Python 3, Vim with jobs/timers and JSON support, and local checkouts of
Neosnippet, context_filetype, and vim-lsp. No language server installation is needed.

```sh
CONTEXT_FILETYPE_RTP=/path/to/context_filetype.vim \
NEOSNIPPET_RTP=/path/to/neosnippet.vim \
VIM_LSP_RTP=/path/to/vim-lsp \
python3 test/run.py
```

The checks exercise insertion, escaping, quotes, Unicode, literal backticks,
continuation indentation, numbered field order, and jumping to the final tabstop.
A minimal LSP fixture also exercises multiline, quoted, and Unicode completions
through Vim's built-in omnifunc. Set `ADAPTER_RTP` to an unpatched checkout to
verify that the multiline regression fails there.

JSON-object snippets and escaped-dollar snippets are tested directly at the
adapter boundary: the tested vim-lsp version independently mishandles their
completion preview words before calling the adapter. This patch does not change
vim-lsp's completion preview or add support for snippet choices or transforms.
