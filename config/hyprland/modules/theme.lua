-- Theme settings (colors and animations).

local function rgb(hex)  return "rgb("  .. hex .. ")" end
local function rgba(hex) return "rgba(" .. hex .. ")" end

-- Color definitions
_G.black = rgb("000000")
_G.white = rgb("FFFFFF")
_G.red   = rgb("FF0000")
_G.green = rgb("00FF00")
_G.blue  = rgb("0000FF")

hl.config({
    -- Design.
    general = {
        gaps_in  = 4,
        gaps_out = 5,
        border_size = 2,
        col = {
            inactive_border = { colors = { BG_LIGHT, BG_DARK } },
        },
        resize_on_border = true,
        allow_tearing    = true,
        layout           = "dwindle",
    },

    -- Effects.
    decoration = {
        rounding       = 10,
        rounding_power = 3,
        active_opacity   = 1,
        inactive_opacity = .85,

        shadow = {
            enabled      = true,
            range        = 20,
            render_power = 3,
            color        = BG_DARK,
        },

        blur = {
            enabled           = true,
            size              = 2,
            passes            = 2,
            new_optimizations = true,
            vibrancy          = .25,
            ignore_opacity    = true,
            xray              = false,
        },
    },

    animations = { enabled = true },
})

local beziers = {
    easeInOutQuad  = {0.45, 0, 0.55, 1},
    easeInOutQuart = {0.77, 0, 0.18, 1},
    easeInOutSine  = {0.37, 0, 0.63, 1},
    default        = {0.05, 0.9, 0.1, 1.05},
    liner          = {1, 1, 1, 1},
    notify         = {0.05, 0.9, 0.1, 1.05},
    window         = {0.13, 0.99, 0.29, 1.08},
    workspace      = {0.1, 1.2, 0.5, 1},
    quick          = {0.15, 0, 0.1, 1},
    liquid         = {0.34, 1.6, 0.4, 0.95}
}

for name, points in pairs(beziers) do
    hl.curve(name, { type = "bezier", points = { {points[1], points[2]}, {points[3], points[4]} } })
end

-- 2. Define animations
local animations = {
    { leaf = "windowsIn",   enabled = true, speed = 7,  bezier = "window", style = "popin" },
    { leaf = "windowsOut",  enabled = true, speed = 5,  bezier = "window", style = "popin" },
    { leaf = "windowsMove", enabled = true, speed = 6,  bezier = "window", style = "slide" },
    { leaf = "layersIn",    enabled = true, speed = 5,  bezier = "notify", style = "popin" },
    { leaf = "layersOut",   enabled = true, speed = 3,  bezier = "easeInOutQuad", style = "popin" },
    { leaf = "fadeIn",      enabled = true, speed = 10, bezier = "window" },
    { leaf = "fadeOut",     enabled = true, speed = 10, bezier = "window" },
    { leaf = "fadeSwitch",  enabled = true, speed = 10, bezier = "window" },
    { leaf = "fadeShadow",  enabled = true, speed = 10, bezier = "default" },
    { leaf = "fadeDim",     enabled = true, speed = 10, bezier = "default" },
    { leaf = "fadeLayers",  enabled = true, speed = 10, bezier = "default" },
    { leaf = "workspaces",  enabled = true, speed = 7,  bezier = "workspace", style = "slidefadevert" },
    { leaf = "border",      enabled = true, speed = 1,  bezier = "liner" },
    { leaf = "borderangle", enabled = true, speed = 20, bezier = "easeInOutQuad", style = "loop" },
}

for _, anim in ipairs(animations) do
    hl.animation(anim)
end