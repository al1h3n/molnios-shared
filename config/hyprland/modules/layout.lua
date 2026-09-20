-- Dwindle for togglesplit, layout, window priorities, swallow.
hl.config({
    general = {
        layout = "scrolling", -- Or dwindle for default layout.
        resize_on_border = true,
    },
    dwindle = {
        preserve_split = true,  -- Required for togglesplit to actually stick.
        smart_split    = false,
        smart_resizing = true,
    },
    master = { new_status = master },
    scrolling = {},
    misc = {
        enable_swallow = 1,
        swallow_regex = "^(Alacritty|kitty|foot|footclient|firefox|org.wezfurlong.wezterm|com.mitchellh.ghostty)$",
    },
})