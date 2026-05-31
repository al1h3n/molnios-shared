-- wezterm config - made for MolniOS.

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

local gpucache = require("gpucache")
config.webgpu_preferred_adapter = gpucache.get_vulkan_gpu()

require("binds")
require("colors")
require("performance")
require("style")
require("syntax")
require("tabs")

return config