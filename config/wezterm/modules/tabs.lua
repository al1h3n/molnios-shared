-- Powerline tab bar style
config.use_fancy_tab_bar = false

-- 1. Load wal colors
local function load_wal_colors()
  local sources = {
    os.getenv("HOME") .. "/.cache/wallust/colors",
    os.getenv("HOME") .. "/.cache/wal/colors",
  }
  for _, path in ipairs(sources) do
    local f = io.open(path, "r")
    if f then
      local colors = {}
      for line in f:lines() do
        local idx, hex = line:match("color(%d+)='(#%x%x%x%x%x%x)'")
        if idx and hex then
          colors[tonumber(idx)] = hex
        end
        local key, val = line:match("(%a+)='(#%x%x%x%x%x%x)'")
        if key and val then
          colors[key] = val
        end
      end
      f:close()
      if next(colors) then return colors end
    end
  end
  return nil
end

-- 2. Resolve palette (c must exist before col is defined)
local fallback = {
  [0]  = '#010102',
  [1]  = '#1F1F22',
  [2]  = '#333439',
  [4]  = '#5C5D63',
  [7]  = '#B9B9BB',
  [8]  = '#7B7B7D',
  [15] = '#D3D3D4',
  background = '#010101',
  foreground = '#C9C9CB',
}
local c = load_wal_colors() or fallback

-- 3. Helper — defined AFTER c
local function col(...)
  for _, idx in ipairs({ ... }) do
    if c[idx] then return c[idx] end
  end
  return '#000000'
end

-- 4. Powerline glyphs
local SOLID_LEFT_ARROW  = wezterm.nerdfonts.pl_right_hard_divider
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider

-- 5. Tab title renderer (uses wal colors too)
wezterm.on('format-tab-title', function(tab, tabs, panes, cfg, hover, max_width)
  local background = col(1, 2)
  local foreground = col(8, 7)
  local edge_bg    = c.background or '#010101'

  if tab.is_active then
    background = col(4, 5, 6)
    foreground = col(0, 1)
  elseif hover then
    background = col(2, 1)
    foreground = col(15, 7)
  end

  local title = tab.active_pane.title
  if #title > max_width - 4 then
    title = wezterm.truncate_right(title, max_width - 4) .. '…'
  end

  return {
    { Background = { Color = edge_bg } },
    { Foreground = { Color = background } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = ' ' .. (tab.tab_index + 1) .. ': ' .. title .. ' ' },
    { Background = { Color = edge_bg } },
    { Foreground = { Color = background } },
    { Text = SOLID_RIGHT_ARROW },
  }
end)

-- 6. Static tab bar colors
config.colors = config.colors or {}
config.colors.tab_bar = {
  background = c.background or '#010101',
  active_tab = {
    bg_color  = col(4, 5, 6),
    fg_color  = col(0, 1),
    intensity = 'Bold',
  },
  inactive_tab = {
    bg_color = col(0, 1),
    fg_color = col(8, 7),
  },
  inactive_tab_hover = {
    bg_color = col(1, 2),
    fg_color = col(15, 7),
  },
  new_tab = {
    bg_color = c.background or '#010101',
    fg_color = col(8, 7),
  },
  new_tab_hover = {
    bg_color = c.background or '#010101',
    fg_color = col(15, 7),
  },
}