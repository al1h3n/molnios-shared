-- wezterm config v1 - made for MolniOS.

-- 1. Custom variables and directories.
local home = os.getenv("HOME")
local l_path = os.getenv("L_PATH") or (home .. "/.local/share/molnios")
_G.dir = l_path
_G.conf = l_path .. "/config/"
_G.scripts = l_path .. "/scripts/"
package.path = package.path .. ";" .. conf .. "wezterm/modules/?.lua"
-- package.path = package.path .. ";" .. home .. "/repo/molnios-shared/config/wezterm/modules/?.lua"

-- 2. Standart variables.
_G.wezterm = require("wezterm")
_G.config = wezterm.config_builder()

if config.front_end == "WebGpu" and wezterm.gui then
    local gpucache = require("gpucache")
    local adapter = gpucache.get_vulkan_gpu()
    if adapter then
        config.webgpu_preferred_adapter = adapter
    end
end

-- 3. Imports.
require("binds")
require("colors")
require("performance")
require("style")
require("syntax")
require("tabs")

-- Noctalia v5 colors import.
local noctalia_colors_file = wezterm.config_dir .. '/colors/Noctalia.toml'
wezterm.color.load_scheme(noctalia_colors_file)

return config