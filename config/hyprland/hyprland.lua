-- hyprconfig (lua edition) - made for MolniOS.
-- Most of the comments are cut, find them in monolithic edition.
-- Version: 1.0.1.

-- 1. Resolve your $L_PATH and $conf variables dynamically
local home = os.getenv("HOME")
local l_path = os.getenv("L_PATH") or (home .. "/.local/share/molnios")
local conf = l_path .. "/config/"

-- 2. Tell Lua to look for modules in $conf/hyprland/modules
package.path = package.path .. ";" .. conf .. "hyprland/modules/?.lua"

-- 3. Expose global variables for other modules.
_G.dir = l_path
_G.conf = conf
_G.scripts = l_path .. "/scripts/"
_G.conf_mono = conf .. "/hyprland-monolithic/"
_G.conf_lua = conf .. "/hyprland/"

-- 4. Load your modules sequentially.
-- You can use require("folder.luafile") too.

-- Mandatory for work.
require("custom-theme")
require("env")
require("variables")

-- Other modules.
require("animations")
require("binds")
require("input")
require("layout")
require("misc")
require("monitors")
require("rules")
require("system")
require("theme")
require("visual")

-- Hyprmod's module.
require("hyprland-gui")