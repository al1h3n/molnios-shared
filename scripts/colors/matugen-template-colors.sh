#!/bin/sh

# Pywal-compatible colors.sh template for Matugen
# Generates shell variables compatible with pywal/wallust

# Base16 colors
color0="{{colors.primary.default.hex}}"
color1="{{colors.red.default.hex}}"
color2="{{colors.green.default.hex}}"
color3="{{colors.yellow.default.hex}}"
color4="{{colors.blue.default.hex}}"
color5="{{colors.magenta.default.hex}}"
color6="{{colors.cyan.default.hex}}"
color7="{{colors.on_primary.default.hex}}"
color8="{{colors.primary_container.default.hex}}"
color9="{{colors.red.default.hex}}"
color10="{{colors.green.default.hex}}"
color11="{{colors.yellow.default.hex}}"
color12="{{colors.blue.default.hex}}"
color13="{{colors.magenta.default.hex}}"
color14="{{colors.cyan.default.hex}}"
color15="{{colors.on_primary.default.hex}}"

# Semantic colors
background="{{colors.primary.default.hex}}"
foreground="{{colors.on_primary.default.hex}}"
cursor="{{colors.on_primary.default.hex}}"

# Export for scripts
export color0 color1 color2 color3 color4 color5 color6 color7
export color8 color9 color10 color11 color12 color13 color14 color15
export background foreground cursor
