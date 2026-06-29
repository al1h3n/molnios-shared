-- General (tearing), debug (vfr), and autostarts.

-- Autostart
hl.on("hyprland.start", function()
    -- Network and Bluetooth
    hl.exec_cmd(network .. " & " .. bluetooth)

    -- Polkit agent
    --[[
    hl.exec_cmd(
        "systemctl --user start polkit-gnome-authentication-agent-1" ..
        "|| hyprpolkitagent" ..
        "|| /usr/libexec/hyprpolkitagent" ..
        "|| /usr/lib/hyprpolkitagent" ..
        "|| /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
    )
    ]]

    -- Wallpaper, tray, and other main additions.
    hl.exec_cmd(noctalia .. " & " .. switcherdaemon .. " & " .. eyedropper .. " & " .. wallpaper .. " && " .. idlewallpaper .. " && " .. borders)

    -- Notifications
    hl.exec_cmd(notify)wallpaper

    -- Clipboard managers
    hl.exec_cmd(cliptext .. " & " .. clipmage .. " & " .. clipsave)

    -- Additional programs
    hl.exec_cmd("faillock --reset")
end)

hl.config({
    general = { allow_tearing = true },
    debug = { vfr = 1 },
})