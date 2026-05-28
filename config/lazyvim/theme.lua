-- ~/.local/share/molnios/config/lazyvim/theme.lua

-- ─── Backend Detection ────────────────────────────────────────────────────────

local cache_dir = vim.fn.expand(
  (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache"))
)

local molnios_cache   = cache_dir .. "/molnios/colors"
local molnios_json    = cache_dir .. "/molnios/colors.json"
local wallust_json    = cache_dir .. "/wallust/colors.json"
local pywal_json      = cache_dir .. "/wal/colors.json"

local function read_first_line(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local line = f:read("*line")
  f:close()
  return line
end

local function detect_backend()
  -- 1. Read molnios cache (contains the sequences file path)
  local line = read_first_line(molnios_cache)
  if line then
    if line:match("wallust") then return "wallust" end
    if line:match("/wal/")   then return "pywal"   end
  end

  -- 2. Fallback: detect from existing json files
  if vim.fn.filereadable(wallust_json) == 1 then return "wallust" end
  if vim.fn.filereadable(pywal_json)   == 1 then return "pywal"   end

  return nil  -- no colors available
end

local function resolve_colors_json(backend)
  -- Prefer the molnios-copied json (unified path for neopywal)
  if vim.fn.filereadable(molnios_json) == 1 then
    return molnios_json
  end
  if backend == "wallust" and vim.fn.filereadable(wallust_json) == 1 then
    return wallust_json
  end
  if backend == "pywal" and vim.fn.filereadable(pywal_json) == 1 then
    return pywal_json
  end
  return nil
end

local backend    = detect_backend()
local colors_json = backend and resolve_colors_json(backend) or nil
local has_colors  = colors_json ~= nil

-- ─── Debug (remove after confirming it works) ─────────────────────────────────
-- vim.notify("backend=" .. tostring(backend) .. " json=" .. tostring(colors_json))

-- ─── Plugin Specs ─────────────────────────────────────────────────────────────

return {
  -- Always load gruvbox as fallback
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

  -- Only add neopywal spec when colors are actually available
  has_colors and {
    "RedsXDD/neopywal.nvim",
    name    = "neopywal",
    priority = 1001,
    opts = {
      use_palette             = backend,
      transparent_background  = true,
      -- Point neopywal at the resolved json path
      colorscheme_file        = colors_json,
    },
    config = function(_, opts)
      require("neopywal").setup(opts)
    end,
  } or nil,

  -- LazyVim colorscheme resolution
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = has_colors and "neopywal" or "gruvbox",
    },
  },
}