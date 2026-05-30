local settings = {
    -- Char select - UTF symbols and emojis.
    -- char_select_bg_color = "#282828",
    char_select_font = wezterm.font "SFMono Nerd Font Medium",
    char_select_font_size = 14,
    window_background_opacity = .6,

    -- Action launcher.
    -- command_palette_bg_color = '#282828',
    command_palette_font = wezterm.font "SFMono Nerd Font Medium",
    command_palette_rows = 15,

    -- Scrollbar
    enable_scroll_bar = true,

    -- Font
    font = wezterm.font('JetBrains Mono Nerd Font', { weight = 'Bold'}),
    font_size = 14,

    initial_cols = 120,
    initial_rows = 30, -- usually paired with initial_rows
}

for k, v in pairs(settings) do
    config[k] = v
end