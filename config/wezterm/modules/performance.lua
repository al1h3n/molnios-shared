-- Affecting perfomance settings.

local settings = {
    animation_fps = 154; -- For blinking things.
    audible_bell = "Disabled",
    default_cursor_style = 'BlinkingBlock',
    front_end = "WebGpu",
    kde_window_background_blur = true,
    macos_window_background_blur = 15,
    max_fps = 154,
    prefer_egl = false,
    webgpu_power_preference = "HighPerformance",
    win32_system_backdrop = "Acrylic", -- Tabbed for W11, Acryllic for W10.
}

for k, v in pairs(settings) do
    config[k] = v
end

-- if wezterm.gui then
--   local gpus = wezterm.gui.enumerate_gpus()
--   for _, gpu in ipairs(gpus) do
--     if gpu.backend == "Vulkan" then
--       config.webgpu_preferred_adapter = gpu
--       break
--     end
--   end
-- end