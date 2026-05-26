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
      use_palette = "wallust", -- Tells the plugin to read Wallust json caches
      transparent_background = true,
    },
    config = function(_, opts)
      local neopywal = require("neopywal")

      -- Attempt to compile/load Wallust colors
      neopywal.setup(opts)

      -- Check if Wallust/Pywal cache files actually exist on the system
      if neopywal.has_colorscheme() then
        vim.cmd("colorscheme neopywal")
      else
        -- Fallback to Gruvbox if no wallust files are found
        vim.cmd("colorscheme gruvbox")
      end
    end,
  },

  -- 3. Set the default LazyVim colorscheme dynamically
  {
    "LazyVim/LazyVim",
    opts = function()
      -- This ensures LazyVim's internal picker knows which scheme is active
      local has_wallust = require("neopywal").has_colorscheme()
      return {
        colorscheme = has_wallust and "neopywal" or "gruvbox",
      }
    end,
  },
}