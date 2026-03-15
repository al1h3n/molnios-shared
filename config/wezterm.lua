-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()
local style = require('weztermstyle')

-- 1. Config.
local overrides = {
    allow_win32_input_mode = true,
    animation_fps = 30;
    -- background wezterm.org/config/lua/config/background.html
    font_size = 14,
    color_scheme = "Catppuccin Mocha",
}

for k, v in pairs(overrides) do
    config[k] = v
end

-- and finally, return the configuration to wezterm
return config
