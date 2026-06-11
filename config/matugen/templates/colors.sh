#!/bin/sh
# Pywal-compatible colors.sh for Matugen
# Maps Material You roles → 16-color terminal palette.
# Valid variable names come from matugen's Material 3 scheme output.
# ==============================================================================

# 0 – background (darkest surface)
color0="{{colors.background.default.hex}}"
# 1 – red   → Material You "error" role is always red-family
color1="{{colors.error.default.hex}}"
# 2 – green → tertiary is the complementary hue; often green/teal
color2="{{colors.tertiary.default.hex}}"
# 3 – yellow → secondary is the warm accent; often amber/yellow
color3="{{colors.secondary.default.hex}}"
# 4 – blue  → primary is the dominant accent
color4="{{colors.primary.default.hex}}"
# 5 – magenta → inverse_primary is a lighter/shifted version of primary
color5="{{colors.inverse_primary.default.hex}}"
# 6 – cyan  → outline_variant is a cool mid-tone
color6="{{colors.outline_variant.default.hex}}"
# 7 – white → on_background is the standard foreground colour
color7="{{colors.on_background.default.hex}}"

# Brights: use container/on variants for the lighter half of the 16-color set
color8="{{colors.surface_variant.default.hex}}"
color9="{{colors.error_container.default.hex}}"
color10="{{colors.tertiary_container.default.hex}}"
color11="{{colors.secondary_container.default.hex}}"
color12="{{colors.primary_container.default.hex}}"
color13="{{colors.on_secondary_container.default.hex}}"
color14="{{colors.on_tertiary_container.default.hex}}"
color15="{{colors.on_surface.default.hex}}"

# Semantic aliases
background="{{colors.background.default.hex}}"
foreground="{{colors.on_background.default.hex}}"
cursor="{{colors.on_background.default.hex}}"

export color0 color1 color2 color3 color4 color5 color6 color7
export color8 color9 color10 color11 color12 color13 color14 color15
export background foreground cursor
