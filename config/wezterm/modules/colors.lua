local settings = {
    -- background wezterm.org/config/lua/config/background.html
    color_scheme = 'Gruvbox Dark (Gogh)', -- wezterm.org/colorschemes/index.html
}

for k, v in pairs(settings) do
    config[k] = v
end