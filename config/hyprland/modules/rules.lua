-- $conf/hyprland/rules.lua

-- =====================================
-- Window rules.
-- =====================================

-- Ignore maximize requests from all apps.
hl.window_rule({
    match = { class = ".*" },
    suppress_event = "maximize"
})

-- XWayland drag fix.
hl.window_rule({
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true
})

-- Smart gaps.
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
hl.window_rule({
    match = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding = 0
})
hl.window_rule({
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding = 0
})

-- Glass effect for permissions.
hl.window_rule({
    match = { class = "^(polkit-gnome-authentication-agent-1)$", float = true },
    dim_around = true,
    center = true,
    opacity = "1 .8"
})

hl.window_rule({
    match = { class = "^(hyprpolkitagent)$", float = true },
    dim_around = true,
    center = true,
    opacity = "1.0 0.8"
})

-- Waybar
hl.window_rule({
    match = { class = "^(waybar)$", title = "^(waybar)$" },
    no_focus = true
})

-- Opaque browsers/players
hl.window_rule({
    match = { class = "^(mpv)$" },
    opacity = "1 override"
})
hl.window_rule({
    match = { class = "^(zen|librewolf|firefox|brave|chrome)$" },
    opacity = "1 override"
})


-- =====================================
-- Layer rules.
-- =====================================

-- Notifications
hl.layer_rule({
    match = { namespace = "notifications" },
    ignore_alpha = 0,
    blur = true,
    animation = "slide right"
})
hl.layer_rule({
    match = { namespace = "swaync-notification-window" },
    ignore_alpha = 0,
    blur = true,
    animation = "slide right"
})
hl.layer_rule({
    match = { namespace = "swaync-control-center" },
    ignore_alpha = 0,
    blur = true,
    animation = "slide right"
})

-- Rofi
hl.layer_rule({
    match = { namespace = "rofi" },
    ignore_alpha = 0,
    blur = true,
    animation = "slide bottom"
})

-- Snappy-switcher (hyprland only).
hl.layer_rule({
    match = { namespace = "snappy-switcher" },
    ignore_alpha = 0,
    blur = true,
    animation = "slide bottom"
})

-- Wlogout
hl.layer_rule({
    match = { namespace = "logout_dialog" },
    blur = true,
    animation = "fade"
})