return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    opts = {
      transparent_mode = true, -- Makes the main background transparent
      overrides = {
        -- Keep these solid for better readability in menus
        LazyNormal = { bg = "#282828" },
        MasonNormal = { bg = "#282828" },
        NormalFloat = { bg = "#282828" },
        FloatBorder = { bg = "#282828" },
      },
    },
    config = function(_, opts)
      require("gruvbox").setup(opts)
      vim.cmd("colorscheme gruvbox")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}