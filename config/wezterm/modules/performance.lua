-- Affecting perfomance settings.

local settings = {
    animation_fps = 154;
    audible_bell = "Disabled",
    default_cursor_style = 'BlinkingBlock',
    -- front_end = "WebGpu",
}

for k, v in pairs(settings) do
    config[k] = v
end

-- if wezterm.gui then
--     for _, gpu in ipairs(wezterm.gui.enumerate_gpus()) do
--         if gpu.backend == "Vulkan" then
--             config.webgpu_preferred_adapter = gpu
--             break
--         end
--     end
-- end