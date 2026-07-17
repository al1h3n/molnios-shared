-- General and decorations (visuals unrelated to perfomance).

local function rgb(hex)  return "rgb("  .. hex .. ")" end
local function rgba(hex) return "rgba(" .. hex .. ")" end

-- Color definitions
_G.black = rgb("000000")
_G.white = rgb("FFFFFF")
_G.red   = rgb("FF0000")
_G.green = rgb("00FF00")
_G.blue  = rgb("0000FF")

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 5,
        border_size = 0,
        col = { inactive_border = { colors = { BG_LIGHT, BG_DARK } }, },
    },
    decoration = {
        rounding = 10,
        rounding_power = 5,
        active_opacity = 1,
        inactive_opacity = .9,
    },
})