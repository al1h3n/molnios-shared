-- GPU index cache.
local M = {}
local _cached = nil

function M.get_vulkan_gpu()
  if _cached then return _cached end
  if not wezterm.gui then return nil end
  for _, gpu in ipairs(wezterm.gui.enumerate_gpus()) do
    if gpu.backend == "Vulkan" then
      _cached = gpu
      return gpu
    end
  end
end

return M