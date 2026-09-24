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

-- 2.1. Front end.
if not os.getenv("NIRI_SOCKET")
    and (os.getenv("XDG_CURRENT_DESKTOP") or ""):lower() ~= "niri" then
    config.front_end = "WebGpu"
end

-- Has to stay after the assignment above, not before it: front_end was only ever
-- set in performance.lua, which is required further down, so this block read a
-- nil front_end and the adapter was never selected.
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

-- Noctalia v5 colors.
-- Noctalia rewrites this file via an atomic replace whenever the palette
-- changes (wallpaper swap, accent change, etc). automatically_reload_config
-- (on by default) only watches wezterm.lua itself, so those updates never
-- reached a running WezTerm without a manual restart. Explicitly watching
-- the file wires it into the same reload machinery, and wezterm's watcher
-- (parent-directory based) survives the atomic replace.
local noctalia_colors_dir = (os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")) .. "/wezterm/colors"
local noctalia_colors_file = noctalia_colors_dir .. "/Noctalia.toml"
wezterm.add_to_config_reload_watch_list(noctalia_colors_file)
local noctalia_scheme = io.open(noctalia_colors_file)
if noctalia_scheme then
    noctalia_scheme:close()
    config.color_scheme_dirs = { noctalia_colors_dir }
    config.color_scheme = "Noctalia"
end

return config