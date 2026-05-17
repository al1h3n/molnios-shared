-- hyprconfig (lua edition) - made dor MolniOS.
-- Most of the comments are cut, find them in monolithic edition.
-- Version: 1.0.1.

-- 1. Resolve your $L_PATH and $conf variables dynamically
local home = os.getenv("HOME")
local l_path = os.getenv("L_PATH") or (home .. "/.local/share/molnios")
local conf = l_path .. "/config"

-- 2. Tell Lua to look for modules in $conf/hyprland/modules
package.path = package.path .. ";" .. conf .. "/hyprland/modules/?.lua"

-- 3. Expose global variables for other
_G.dir = l_path
_G.conf = conf
_G.scripts = l_path .. "/scripts"
_G.conf_mono = conf .. "/hyprland-monolithic"
_G.conf_lua = conf .. "/hyprland"

-- 4. Load your modules sequentially.
require("custom-theme") -- Custom colors & cursors
require("variables")    -- Global paths and command definitions
require("env")          -- Env vars
require("system")       -- Monitors, autostart
require("theme")        -- Look, feel, animations, layouts
require("binds")        -- Keybindings
require("rules")        -- Window and Layer rules
require("input")        -- Keyboard settings
require("misc")         -- Other settings
-- You can use require("folder.luafile") too.