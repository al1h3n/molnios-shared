return {
  {
    "dylanaraps/wal.vim",
    lazy = false,
    priority = 1000,
  },
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    opts = {
      transparent_mode = true,
      overrides = {
        LazyNormal  = { bg = "#282828" },
        MasonNormal = { bg = "#282828" },
        NormalFloat = { bg = "#282828" },
        FloatBorder = { bg = "#282828" },
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "wal", -- gruvbox
    },
  },
}