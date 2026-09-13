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
-- Wayland app_ids, not friendly names: wezterm reports
-- "org.wezfurlong.wezterm", so a "^(wezterm)$" rule never matched it and the
-- window was never tagged. Cross-check with layout.lua's swallow_regex.
local glassed = {
    "kitty",
    "org\\.wezfurlong\\.wezterm",
    "polkit-gnome-authentication-agent-1",
    "hyprpolkitagent",
}
for _, class in ipairs(glassed) do
    hl.window_rule({ match = { class = "^(" .. class .. ")$" }, tag = "+hyprglass_enabled" })
end

if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        -- Whitelist model: off globally, on per tag and per layer.
        enabled = false,
        default_theme = "dark",
        default_preset = "goldengate",
        layers = { enabled = true },
    })

    -- macOS 27 "Golden Gate" Liquid Glass, as close as these knobs get.
    --
    -- Built on "glass" rather than the plugin default: the default is blur 2.0
    -- with refraction 0.6, which is frosted acrylic (Windows Mica), not glass.
    -- Apple's look is the opposite balance - a clear, only lightly frosted
    -- plate whose entire character comes from light bending hard at the rim.
    -- "glass" already carries refraction 8.0, so it is the right base.
    --
    -- macOS 27 is a rendering refinement of 26, not a redesign. Three deltas
    -- carry over to these knobs: more diffusion of busy content behind the
    -- glass, a darkened edge, and brighter specular highlights.
    hg.preset("goldengate", {
        inherits = "glass",

        -- Scattering, not frosting: 1.8 * 12 = ~22px over 4 passes. Up from 26
        -- for the diffusion pass, but still far below the plugin default -
        -- Apple frosts less than every recreation assumes.
        blur_strength   = 1.8,
        blur_iterations = 4,

        -- The reference shader keeps the interior flat and color-accurate and
        -- puts all curvature in the outer sliver, so the dome stays low and the
        -- bezel carries the look. High dome = magnifying glass, not glass.
        lens_distortion = 0.15,
        edge_thickness  = 0.08,

        -- Fringing belongs on a thin rim only. The reference separation is
        -- 3px on a scale where 2-4 reads as glass and 8+ reads as VHS glitch.
        chromatic_aberration = 0.35,

        -- 27's depth cue: edge darker, specular brighter. Fresnel is the rim
        -- *glow*, so it comes down while the highlight goes up (0.6 is the
        -- reference baseline for an untouched 26-era highlight).
        fresnel_strength  = 0.45,
        specular_strength = 0.90,

        -- Cool near-neutral, 6% strength. Apple treats tint as *semantic* - a
        -- blue confirm button, a red destructive one - and warns against tinting
        -- for decoration, so a decorative tint stays near the floor.
        tint_color = 0x8899aa10,

        -- The reference pipeline darkens exactly once (glassColor *= 0.90) and
        -- then ADDS white at the rim (+= vec3(1.0) * rim * 0.55). Net luminance
        -- is roughly neutral. It has no contrast curve, no desaturation and no
        -- adaptive dimming at all - those three are hyprglass extras, and
        -- stacking them under a 0.90 brightness darkened the plate four times
        -- over. 27's "darkened edge" is a thin separation line at the rim, not a
        -- dimmer surface; conflating the two is what made this too dark.
        dark = {
            brightness = 0.94,
            contrast   = 1.0,
            saturation = 0.95,
            vibrancy   = 0.30,
            -- Some dimming stays for the 27 legibility pass, but a quarter, not
            -- half: the blur already flattens a busy background.
            adaptive_dim = 0.25,
        },
        light = {
            brightness     = 1.06,
            contrast       = 1.0,
            saturation     = 0.95,
            vibrancy       = 0.25,
            adaptive_boost = 0.25,
        },
    })

    -- The two ends of macOS 27's Liquid Glass transparency slider, which
    -- replaced 26's binary Reduce Transparency toggle. Both inherit goldengate
    -- and carry only the deltas, so retuning the base retunes all three.
    --
    -- Clear: barely any frosting, the refracted rim does all the work. What the
    -- slider's "ultra clear" end looks like. Legibility over a busy wallpaper
    -- drops - that is the trade the slider exists to expose.
    hg.preset("goldengate_clear", {
        inherits = "goldengate",

        blur_strength   = 0.6,
        blur_iterations = 2,
        glass_opacity   = 0.65,
        tint_color      = 0x8899aa06,

        -- Rim optics stay: without them a clear plate is just a hole.
        chromatic_aberration = 0.4,
        specular_strength    = 0.95,

        dark  = { brightness = 0.97, saturation = 1.0, adaptive_dim = 0.15 },
        light = { brightness = 1.03, saturation = 1.0, adaptive_boost = 0.15 },
    })

    -- Tinted: the frosted end. Frosted, not dark - the distinction matters,
    -- because four knobs here all darken and they multiply. brightness 0.82 with
    -- adaptive_dim 0.6 and tint alpha 0x3c came out dimmer than no glass at all,
    -- which is not what the slider's tinted end does: it scatters more light,
    -- it does not absorb more. So the frosting comes from blur alone, and
    -- brightness sits *above* goldengate's 0.90 to pay for the extra diffusion.
    hg.preset("goldengate_tinted", {
        inherits = "goldengate",

        blur_strength   = 3.2,
        blur_iterations = 5,
        glass_opacity   = 1.0,
        -- 0x28 (16%) not 0x3c (23%): the tint is a hue, not a neutral-density
        -- filter.
        tint_color      = 0x8899aa24,

        -- Frosted glass scatters instead of refracting cleanly, so the rim
        -- optics come down as the diffusion goes up.
        chromatic_aberration = 0.2,
        fresnel_strength     = 0.3,
        lens_distortion      = 0.1,

        dark = {
            -- 0.90 is the reference shader's own glass tint multiplier, and this
            -- is the preset heavy enough to carry it.
            brightness   = 0.90,
            saturation   = 0.85,
            adaptive_dim = 0.40,
        },
        light = {
            brightness     = 1.10,
            saturation     = 0.85,
            adaptive_boost = 0.40,
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
