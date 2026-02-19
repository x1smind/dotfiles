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

require("lazy").setup({
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },
  { "catppuccin/nvim", name = "catppuccin" },
  { "sainnhe/gruvbox-material" },
  { "sainnhe/everforest" },
  { "rebelot/kanagawa.nvim" },
  { "navarasu/onedark.nvim" },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        filesystem = {
          follow_current_file = { enabled = true },
          hijack_netrw_behavior = "open_default",
        },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = 'main', -- This branch requires the new naming
    build = ":TSUpdate",
    config = function()
      -- Change 'configs' to 'config' here
      require("nvim-treesitter.config").setup({
        ensure_installed = { 
          "bash", "html", "lua", "markdown", "javascript", "typescript", 
          "python", "go", "c", "php", "astro", "vim", "vimdoc", "query" 
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
      "nvim-telescope/telescope-file-browser.nvim",
    },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { "%.git/" },
        },
        pickers = {
          find_files = {
            hidden = true,
            no_ignore = true,
          },
        },
      })
      pcall(require("telescope").load_extension, "fzf")
      pcall(require("telescope").load_extension, "file_browser")
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = { theme = "auto", icons_enabled = true },
      })
    end,
  },
})
