return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    opts = {
      transparent_mode = true,
      overrides = {
        LazyNormal = { bg = "#282828" },
        MasonNormal = { bg = "#282828" },
        NormalFloat = { bg = "#282828" },
        FloatBorder = { bg = "#282828" },
      },
    },
    config = function(_, opts)
      require("gruvbox").setup(opts)
    end,
  },
  {
    "RedsXDD/neopywal.nvim",
    name = "neopywal",
    priority = 1000,
    opts = {
      use_palette = "wallust",
      transparent_background = true,
    },
    config = function(_, opts)
      local neopywal = require("neopywal")
      neopywal.setup(opts)

      if neopywal.has_colorscheme() then
        vim.cmd("colorscheme neopywal")
      else
        vim.cmd("colorscheme gruvbox")
      end
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = function()
      -- Safely check if neopywal is available in neovim's runtime path yet
      local status_ok, neopywal = pcall(require, "neopywal")
      local has_wallust = status_ok and neopywal.has_colorscheme()

      return {
        colorscheme = has_wallust and "neopywal" or "gruvbox",
      }
    end,
  },
}