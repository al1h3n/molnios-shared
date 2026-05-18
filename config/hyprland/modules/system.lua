-- Monitor settings, general (tearing), debug (vfr), and autostarts.

-- Monitors
hl.monitor({
    output   = "DP-1",
    mode     = "highres@highrr",
    position = "0x0",
    scale    = "1.25"
})

-- Autostart
hl.on("hyprland.start", function()
    -- Network and Bluetooth
    hl.exec_cmd(network .. " & " .. bluetooth)

    -- Polkit agent
    hl.exec_cmd(
        "systemctl --user start hyprpolkitagent.service 2>/dev/null " ..
        "|| systemctl --user start polkit-gnome-authentication-agent-1.service 2>/dev/null " ..
        "|| /usr/libexec/hyprpolkitagent " ..
        "|| /usr/lib/hyprpolkitagent " ..
        "|| /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
    )

    -- Wallpaper, tray, and other main additions.
    hl.exec_cmd(bar .. " & " .. switcherdaemon .. " & " .. eyedropper .. " & " .. wallpaper .. " && " .. idlewallpaper .. " && " .. borders)

    -- Notifications
    hl.exec_cmd(notify)

    -- Clipboard managers
    hl.exec_cmd(cliptext .. " & " .. clipmage .. " & " .. clipsave)

    -- Additional programs
    hl.exec_cmd("faillock --reset")
end)

hl.config({
    general = { allow_tearing = true, }
    debug = { vfr = 1, }
})