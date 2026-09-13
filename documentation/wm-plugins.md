### [hyprglass](https://github.com/hyprnux/hyprglass)

Loaded by `config/hyprland/modules/hyprglass.lua` via `hl.plugin.load()` during
config parse. It has to happen there: `hl.plugin.hyprglass` does not exist
before the plugin is loaded, so `hyprctl plugin load` from `hyprland.start`
runs too late to configure anything.

A prebuilt `.so` only loads on a Hyprland built with the exact same
aquamarine / hyprutils / hyprlang / hyprcursor / hyprgraphics versions, the
plugin embeds them and refuses to load on a mismatch ("Version mismatch").
Upstream release blobs target the dependency set of the distro they were built
on, which never matches nixpkgs, so no blob is kept in this repo.

On non-NixOS, build it
against the running Hyprland with `hyprpm add https://github.com/hyprnux/hyprglass`
and point that path at the result.

Current settings: effect off globally, whitelisted per window tag (kitty,
wezterm, the two polkit agents) with the custom `tahoe` preset, and per layer
namespace (swaync, rofi, snappy-switcher, logout_dialog, noctalia). Layer
namespaces are matched exactly, no regex, so per-monitor ones like
`noctalia-bar-Main` have to be added by hand.

The noctalia layers use `mask_mode = "alpha"`. Quickshell advertises a blur
region through `ext-background-effect-v1`, that region is a rectangle, and
`auto` masks the glass to it — which is what put square glass corners under
rounded panels. `alpha` masks to the panel's own pixels instead.

Toggle it at runtime from the manager menu (`m` → Compositor → Hyprland →
Decorations → Toggle Liquid Glass), which unloads/loads the plugin. Flipping
`plugin:hyprglass:enabled` would not work: per-window tags override the global
setting.

### [Niri-glass](https://github.com/zaroutt/Niri-glass)

Niri has no plugin API, so glass on niri means running a patched niri. The
`niri-glass` flake input replaces `programs.niri.package` in
`molnixos/pkgs/niri.nix`. It is pinned to the niri rev its overlay files were
written against (49fc611, niri 26.04) — bumping it alone breaks the build, and
nothing caches it, so the niri crate compiles locally.

Configured in `niri.kdl` under `window-rule { background-effect { liquid-glass
{ … } } }`. The menu toggle flips `blur` in that block, since the glass renders
in niri's background-effect path.