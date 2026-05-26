-- Helper function to read the molnios cache and detect the backend
local function get_color_backend()
  local molnios_cache = vim.fn.expand("~/.cache/molnios/colors")

  -- 1. Try to read from the molnios cache directly
  if vim.fn.filereadable(molnios_cache) == 1 then
    local f = io.open(molnios_cache, "r")
    if f then
      local content = f:read("*line") -- Read the first line (the sequence path)
      f:close()
      if content then
        -- Check which sequence file path is stored
        if content:match("wallust") then
          return "wallust", true
        elseif content:match("/wal/") then
          return "pywal", true -- 'pywal' config works for pywal16
        end
      end
    end
  end

  -- 2. Fallback: check default json files directly if molnios cache is missing
  if vim.fn.filereadable(vim.fn.expand("~/.cache/wallust/colors.json")) == 1 then
    return "wallust", true
  elseif vim.fn.filereadable(vim.fn.expand("~/.cache/wal/colors.json")) == 1 then
    return "pywal", true
  end

  -- 3. Default if nothing is found (Gruvbox will trigger because has_colors = false)
  return "wallust", false
end

-- Evaluate color state right before resolving the plugin tables
local backend, has_colors = get_color_backend()

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
      use_palette = backend, -- Dynamically swaps between "wallust" and "pywal"
      transparent_background = true,
    },
    config = function(_, opts)
      require("neopywal").setup(opts)
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      -- Resolves directly at startup using the helper function variable
      colorscheme = has_colors and "neopywal" or "gruvbox",
    },
  },
}