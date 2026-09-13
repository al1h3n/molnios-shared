-- Affecting perfomance settings.
-- front_end is not here: it depends on the compositor and is set in wezterm.lua,
-- which has to happen before the WebGpu adapter lookup there.

-- Every key here is valid on every platform wezterm builds for; the ones that do
-- not apply are ignored without a warning. wayland_window_background_blur needs
-- a compositor that implements a blur protocol (Hyprland, niri, KDE); GNOME does
-- not have one and X11 sessions ignore it, in both cases harmlessly.
local settings = {
    animation_fps = 154; -- For blinking things.
    audible_bell = "Disabled",
    default_cursor_style = 'BlinkingBlock',
    max_fps = 154,
    prefer_egl = false,
    webgpu_power_preference = "HighPerformance",

    wayland_window_background_blur = true,
    macos_window_background_blur = 15,
    win32_system_backdrop = "Acrylic", -- "Mica"/"Tabbed" need W11.
}

for k, v in pairs(settings) do
    config[k] = v
end
