-- Beziers and animations.

-- Disable animations.
-- hl.config({ animations = { enabled = 0 }, })

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

hl.curve("md3_effects_fast", { type = "spring", mass = 1, stiffness = 3800, dampening = 123 })
hl.curve("md3_effects_default", { type = "spring", mass = 1, stiffness = 1600, dampening = 80 })
hl.curve("md3_effects_slow", { type = "spring", mass = 1, stiffness = 800, dampening = 57 })

hl.curve("md3_spatial_fast", { type = "spring", mass = 1, stiffness = 600, dampening = 49 })
hl.curve("md3_spatial_default", { type = "spring", mass = 1, stiffness = 300, dampening = 30 })
hl.curve("md3_spatial_slow", { type = "spring", mass = 1, stiffness = 160, dampening = 25 })

-- 2. Define animations
local animations = {
    -- Less speed, faster it is.

    -- Bouncy (original)
    -- Windows: popin, slide, gnomed. popin/slide are good.
    -- { leaf = "windowsIn",   enabled = true, speed = 7,  bezier = "window", style = "slide" },
    -- { leaf = "windowsOut",  enabled = true, speed = 5,  bezier = "window", style = "popin" },
    -- { leaf = "windowsMove", enabled = true, speed = 6,  bezier = "window", style = "slide" },

    -- { leaf = "layersIn",    enabled = true, speed = 5,  bezier = "notify", style = "popin" },
    -- { leaf = "layersOut",   enabled = true, speed = 3,  bezier = "easeInOutQuad", style = "popin" },

    -- { leaf = "fadeIn",      enabled = true, speed = 10, bezier = "window" },
    -- { leaf = "fadeOut",     enabled = true, speed = 10, bezier = "window" },
    -- { leaf = "fadeSwitch",  enabled = true, speed = 10, bezier = "window" },
    -- { leaf = "fadeShadow",  enabled = true, speed = 10, bezier = "default" },
    -- { leaf = "fadeDim",     enabled = true, speed = 10, bezier = "default" },
    -- { leaf = "fadeLayers",  enabled = true, speed = 10, bezier = "default" },

    -- { leaf = "workspaces",  enabled = true, speed = 6,  bezier = "workspace", style = "slidefadevert" },
    { leaf = "border",      enabled = true, speed = 1,  bezier = "liner" },
    { leaf = "borderangle", enabled = true, speed = 20, bezier = "easeInOutQuad", style = "loop" },

    -- Calm (saneaspect)
    { leaf = "windowsIn", enabled = true, speed = 5,  spring = "md3_spatial_default", style = "popin 92%" },
    { leaf = "windowsOut", enabled = true, speed = 2,  spring = "md3_spatial_default", style = "popin 92%" },
    { leaf = "windowsMove", enabled = true, speed = 5,  spring = "md3_spatial_default" },

    { leaf = "layersIn", enabled = true, speed = 3, spring = "md3_spatial_default" },
    { leaf = "layersOut", enabled = true, speed = 2.5, spring = "md3_spatial_default" },

    { leaf = "fade", enabled = true, speed = 2, spring = "md3_effects_default" },
    { leaf = "fadeOut", enabled = true, speed = 2, spring = "md3_spatial_default" },

    { leaf = "workspaces", enabled = true, speed = 5, spring = "md3_spatial_default", style = "slidevert" },


}

for _, anim in ipairs(animations) do
    hl.animation(anim)
end