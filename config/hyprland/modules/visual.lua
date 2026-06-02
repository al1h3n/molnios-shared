-- Blur and shadows (everything what affects perfomance).
hl.config({
    decoration = {
        shadow = {
            -- enabled = 0, -- Disable shadows.
            range = 25,
            render_power = 3,
            color = BG_DARK,
        },

        blur = {
            -- enabled = 0, -- Disable blur.
            size = 10, -- 2
            passes = 3,
            new_optimizations = true,
            vibrancy = .2,
            contrast = .8,
            noise = .01,
            ignore_opacity = true,
            xray = false,
        },
    },
})