-- Other settings, such as window priorities, branding and debug.
hl.config({
    master = { new_status = master },
    misc = {
      force_default_wallpaper = 1,
      disable_hyprland_logo = 1,
      disable_splash_rendering = 1,

      enable_swallow = 1,
      swallow_regex = "^(Alactritty|kitty|footclient|firefox)$",
    },
    debug = {
      disable_logs = 1,
      enable_stdout_logs = 0,
      vfr = 1,
    },
    ecosystem = { no_update_news = 1 },
})