" Keep vim lean but friendly; prefer Neovim if available
if executable('nvim')
  " Use nvim when typing :q in vim by accident, or tell the user
  echom "Consider using Neovim (nvim) for full config."
endif

set nocompatible
set number
set nowrap
set tabstop=2
set shiftwidth=2
set expandtab
syntax on
filetype plugin indent on
