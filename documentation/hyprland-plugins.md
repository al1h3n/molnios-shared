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

Current settings: effect off globally, kitty whitelisted with the built-in
`glass` preset, glass on the two swaync layer namespaces. Layer namespaces are
matched exactly (no regex), so per-monitor ones like `noctalia-bar-<monitor>`
have to be added by hand.
