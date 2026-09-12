-- The plugin must be loaded during config parse: `hl.plugin.hyprglass` only
-- exists after that. Loading it from hyprland.start (hyprctl plugin load) is
-- too late, the config was already parsed and this file is a no-op.
-- Built from source against the running Hyprland, installed through
-- home.packages. pcall: on a machine without it, skip instead of killing the
-- rest of the config.
pcall(hl.plugin.load, "/etc/profiles/per-user/" .. (os.getenv("USER") or "") .. "/lib/libhyprglass.so")

if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        -- Off by default, whitelisted per window below. Every glassed window
        -- costs a blur + refraction pass over the framebuffer behind it.
        enabled = false,

        -- "glass" is the built-in liquid glass preset: thick slab, heavy edge
        -- refraction (8.0), chromatic aberration, no color tint. "clear" is a
        -- flat transparent plate with the blur turned off - not liquid glass.
        default_theme = "dark",
        default_preset = "glass",

        -- Glass on layer surfaces (bars, notifications), off by default.
        layers = { enabled = true },
    })

    -- Layer whitelist. Namespaces match exactly, no regex, so per-monitor
    -- namespaces (noctalia-bar-<monitor>) have to be listed by hand.
    -- mask_threshold is the hyprglass counterpart of layer_rule ignore_alpha:
    -- glass replaces Hyprland's blur on these layers.
    hg.layer("swaync-control-center", { mask_threshold = 0.1 })
    hg.layer("swaync-notification-window", { mask_threshold = 0.1 })

    -- Windows. kitty is glassed, everything else (wezterm included) is not.
    hl.window_rule({
        match = { class = "^(kitty)$" },
        tag = "+hyprglass_enabled"
    })
end
