-- Bootstrap lazy.nvim (plugin manager) on first run
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Basic options
vim.g.mapleader = " "
vim.o.termguicolors = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.smartindent = true

require("lazy").setup({
  -- LazyVim core (optional; lightweight selection)
  { "folke/tokyonight.nvim" },
  { "nvim-lualine/lualine.nvim" },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  { "tpope/vim-surround" },
  { "tpope/vim-repeat" },
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
})

-- Simple statusline
require("lualine").setup({ options = { theme = "auto" } })

-- Keymaps
vim.keymap.set("n", "<leader>ff", function() require("telescope.builtin").find_files() end)
vim.keymap.set("n", "<leader>fg", function() require("telescope.builtin").live_grep() end)
