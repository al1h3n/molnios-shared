config.use_fancy_tab_bar = false

local c = {
  bg     = "#010101",
  tab    = "#1F1F22",
  hover  = "#333439",
  active = "#5C5D63",
  fg     = "#B9B9BB",
  dim    = "#7B7B7D",
  bright = "#D3D3D4",
  dark   = "#010102",
}

local LEFT  = wezterm.nerdfonts.pl_right_hard_divider
local RIGHT = wezterm.nerdfonts.pl_left_hard_divider

wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
  local bg = c.tab
  local fg = c.dim

  if tab.is_active then
    bg, fg = c.active, c.dark
  elseif hover then
    bg, fg = c.hover, c.bright
  end

  local title = wezterm.truncate_right(
    tab.active_pane.title,
    max_width - 4
  )

  return {
    { Background = { Color = c.bg } },
    { Foreground = { Color = bg } },
    { Text = LEFT },

    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = string.format(" %d: %s ", tab.tab_index + 1, title) },

    { Background = { Color = c.bg } },
    { Foreground = { Color = bg } },
    { Text = RIGHT },
  }
end)

config.colors = {
  tab_bar = {
    background = c.bg,

    active_tab = {
      bg_color = c.active,
      fg_color = c.dark,
      intensity = "Bold",
    },

    inactive_tab = {
      bg_color = c.tab,
      fg_color = c.dim,
    },

    inactive_tab_hover = {
      bg_color = c.hover,
      fg_color = c.bright,
    },

    new_tab = {
      bg_color = c.bg,
      fg_color = c.dim,
    },

    new_tab_hover = {
      bg_color = c.bg,
      fg_color = c.bright,
    },
  },
}