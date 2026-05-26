return {
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
    "RedsXDD/neopywal.nvim",
    name = "neopywal",
    priority = 1001, -- load before LazyVim resolves colorscheme
    opts = {
      use_palette = "wallust",
      transparent_background = true,
    },
    config = function(_, opts)
      -- Just set up the plugin; LazyVim opts below picks the colorscheme
      require("neopywal").setup(opts)
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = function()
      -- Check cache files directly — no plugin API needed
      local has_colors =
        vim.fn.filereadable(vim.fn.expand("~/.cache/wallust/colors.json")) == 1
        or vim.fn.filereadable(vim.fn.expand("~/.cache/wal/colors.json")) == 1

      return {
        colorscheme = has_colors and "neopywal" or "gruvbox",
      }
    end,
  },
}