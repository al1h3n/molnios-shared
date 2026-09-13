-- Affecting perfomance settings.
-- front_end is not here: it is compositor-dependent and set in wezterm.lua's
-- platform block, which has to run before the WebGpu adapter lookup.

local settings = {
    animation_fps = 154; -- For blinking things.
    audible_bell = "Disabled",
    default_cursor_style = 'BlinkingBlock',
    max_fps = 154,
    prefer_egl = false,
    webgpu_power_preference = "HighPerformance",
    win32_system_backdrop = "Acrylic", -- Tabbed for W11, Acryllic for W10.
}

if platform ~= "macos" then
    settings.wayland_window_background_blur = true
else
    settings.macos_window_background_blur = 15
end

for k, v in pairs(settings) do
    config[k] = v
end
