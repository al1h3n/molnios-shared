-- HyprGlass - Liquid Glass.
--
-- hl.plugin.load() only queues the path; Hyprland loads it after the parse and
-- reloads by itself, so hl.plugin.hyprglass is nil on the first pass and the
-- guarded block below runs on the second. A failed load is cached by path, so
-- after a rebuild that changed the .so, restart Hyprland - reload won't retry.
hl.plugin.load("/etc/profiles/per-user/" .. (os.getenv("USER") or "") .. "/lib/libhyprglass.so")

-- Tags are plain Hyprland tags, free without the plugin, so they are set on
-- every parse.
--
-- Only transparent windows are listed. Glass draws *behind* the window surface,
-- so on an opaque window it is invisible and pure GPU cost - which is why the
-- browsers and mpv forced to "1 override" in rules.lua are not here.
--
-- Do not add a `{ fullscreen = true } -> +hyprglass_disabled` rule. `+tag` is
-- additive and is never withdrawn when the match stops holding, so one
-- fullscreen toggle would kill glass on that window until it is closed.
local glassed = { "kitty", "wezterm", "polkit-gnome-authentication-agent-1", "hyprpolkitagent" }
for _, class in ipairs(glassed) do
    hl.window_rule({ match = { class = "^(" .. class .. ")$" }, tag = "+hyprglass_enabled" })
end

if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        -- Whitelist model: off globally, on per tag and per layer.
        enabled = false,
        default_theme = "dark",
        default_preset = "tahoe",
        layers = { enabled = true },
    })

    -- macOS 26 "Tahoe" Liquid Glass, as close as these knobs get.
    --
    -- Built on "glass" rather than the plugin default: the default is blur 2.0
    -- with refraction 0.6, which is frosted acrylic (Windows Mica), not glass.
    -- Apple's look is the opposite balance - a clear, only lightly frosted
    -- plate whose entire character comes from light bending hard at the rim.
    -- "glass" already carries refraction 8.0, so it is the right base.
    hg.preset("tahoe", {
        inherits = "glass",

        -- Light scattering, not frosting. 1.5 * 12 = 18px radius, 3 passes for
        -- a smooth falloff. Apple frosts less than every recreation assumes.
        blur_strength   = 1.5,
        blur_iterations = 3,
        -- refraction_strength = 1,

        -- Curvature lives at the rim; the middle of the plate stays flat so
        -- terminal text under it is not magnified or warped.
        lens_distortion = 0.25,
        edge_thickness  = 0.08,

        -- A thin colour fringe at the rim is what separates glass from a
        -- magnifying lens. Past ~0.5 it stops reading as optics and starts
        -- reading as a VHS glitch.
        chromatic_aberration = 0.4,

        -- Brighter specular + a darker edge is the 26.1/27 depth refinement.
        fresnel_strength  = 0.65,
        specular_strength = 0.95,

        -- Cool near-neutral, 8% strength. Apple tints barely at all.
        tint_color = 0x8899aa14,

        dark = {
            brightness = 0.95,
            contrast   = 1.05,
            saturation = 0.85,
            vibrancy   = 0.30,
            -- The legibility fix: pull down bright backgrounds so text on the
            -- glass survives a busy wallpaper. Apple shipped this as
            -- "better diffusion of busy content" in macOS 27.
            adaptive_dim = 0.35,
        },
        light = {
            brightness    = 1.10,
            contrast      = 0.95,
            saturation    = 0.90,
            vibrancy      = 0.25,
            adaptive_boost = 0.35,
        },
    })

    -- Namespaces match exactly, no regex, so per-monitor ones are listed by
    -- hand. mask_threshold is layer_rule ignore_alpha, kept above the shadow
    -- alpha so the glass does not bleed into the drop shadow.
    for _, ns in ipairs({
        "swaync-control-center",
        "swaync-notification-window",
        "rofi",
        "snappy-switcher",
        "logout_dialog",
    }) do
        hg.layer(ns, { mask_threshold = 0.1 })
    end

    -- mask_mode "alpha" is what rounds the corners. Quickshell advertises a
    -- blur region through ext-background-effect-v1 and that region is a plain
    -- rectangle, so "auto" masks the glass to it and the rounded panel sits on
    -- a square plate. "alpha" masks to the panel's own pixels instead, which
    -- carry its corner radius.
    for _, ns in ipairs({
        "noctalia-bar-Main",
        "noctalia-dock",
        "noctalia-panel",
        "noctalia-notification",
    }) do
        hg.layer(ns, { mask_threshold = 0.5, mask_mode = "alpha" })
    end
end
