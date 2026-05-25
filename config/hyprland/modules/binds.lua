-- Leader key and keybinds.
local M    = "SUPER"
local exec = hl.dsp.exec_cmd

-- ─── Simple exec binds ────────────────────────────────────────────────────────
local binds = {
    -- Top row [Q~Y].
    { M.." + Q", terminal },
    { M.." + E", explorer },
    { M.." + R", appmenu },
    { M.." + T", commandmenu },
    { M.." + Y", vmanager },
    -- Middle row [A~H].
    { M.." + A", notes },
    { M.." + S", browser },
    { M.." + G", discord },
    { M.." + H", telegram },
    -- Bottom row [X~B].
    { M.." + X", emojimenu },
    { M.." + V", clipman },
    { M.." + B", ocr },
    -- Grave / end.
    { M.." + grave",       editor },
    { M.." + SHIFT + grave", shell .. scripts .. "menu/launch-menu.sh" },
    { M.." + end",         actionmenu },

    -- SHIFT row — window management.
    { M.." + SHIFT + Q", multiterminal },
    { M.." + SHIFT + W", hl.dsp.layout("togglesplit") },
    { M.." + SHIFT + E", explorercli },
    { M.." + SHIFT + R", shell .. scripts .. "wallpaper.sh -r" },
    -- SHIFT row — swap windows.
    { M.." + SHIFT + A", hl.dsp.window.swap({ direction = "left"  }) },
    { M.." + SHIFT + S", hl.dsp.window.swap({ direction = "up"    }) },
    { M.." + SHIFT + D", hl.dsp.window.swap({ direction = "down"  }) },
    { M.." + SHIFT + F", hl.dsp.window.swap({ direction = "right" }) },
    -- SHIFT row — apps.
    { M.." + SHIFT + G", gamemode },
    { M.." + SHIFT + H", wallpaperengine },
    { M.." + SHIFT + Z", coder },
    { M.." + SHIFT + X", musicplayer },
    { M.." + SHIFT + C", player },
    { M.." + SHIFT + V", blueman },
    { M.." + SHIFT + B", netman },

    -- CTRL row.
    { M.." + CTRL + Z", reload },

    -- ALT row — eyedropper signals.
    { M.." + ALT + Q", hl.dsp.window.pseudo() },
    { M.." + ALT + Z", "pkill -SIGUSR1 " .. eyedropper },
    { M.." + ALT + X", "pkill -SIGUSR2 " .. eyedropper },

    -- Focus — arrow keys.
    { M.." + left",  hl.dsp.focus({ direction = "left"  }) },
    { M.." + right", hl.dsp.focus({ direction = "right" }) },
    { M.." + up",    hl.dsp.focus({ direction = "up"    }) },
    { M.." + down",  hl.dsp.focus({ direction = "down"  }) },

    -- Screenshot / record.
    { "print",                   screenshot_clip_hyprshot },  -- bare print = region screenshot
    { M.." + insert",            ocr_simple },
    { M.." + print",             record },
    { M.." + SHIFT + print",     record .. " -a" },
    { M.." + CTRL  + print",     record .. " -o" },

    -- System.
    { M.." + space",         "hyprctl switchxkblayout current next" },
    { M.." + escape",        "systemctl hybrid-sleep" },
    { M.." + SHIFT + escape", lock },

    -- Zoom.
    { M.." + SHIFT + up",
        "hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float * 2.5')" },
    { M.." + SHIFT + down",
        "hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '(.float * .25) | if . < 1 then 1 else . end')" },
}

for _, b in ipairs(binds) do
    local dispatcher = type(b[2]) == "string" and exec(b[2]) or b[2]
    hl.bind(b[1], dispatcher)
end

-- ─── Non-exec binds ───────────────────────────────────────────────────────────
hl.bind(M.." + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind(M.." + F", hl.dsp.window.fullscreen())
hl.bind(M.." + Z", hl.dsp.exit())
hl.bind(M.." + C", hl.dsp.window.close())
hl.bind(M.." + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(M.." + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ─── Show desktop (D) ─────────────────────────────────────────────────────────
-- Replicates the 5-step toggle from the monolithic config.
hl.bind(M.." + D", hl.dsp.workspace.toggle_special("magic"))
hl.bind(M.." + D", hl.dsp.window.move({ workspace = "+0" }))
hl.bind(M.." + D", hl.dsp.workspace.toggle_special("magic"))
hl.bind(M.." + D", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(M.." + D", hl.dsp.workspace.toggle_special("magic"))

-- ─── Special workspaces ───────────────────────────────────────────────────────
hl.bind(M.." + P",        hl.dsp.workspace.toggle_special("magic"))
hl.bind(M.." + SHIFT + P", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(M.." + CTRL  + P", hl.dsp.window.move({ workspace = "+0" }))

-- ─── Workspaces 1–10 ──────────────────────────────────────────────────────────
for i = 1, 10 do
    local key = i % 10
    hl.bind(M.." + "..key,         hl.dsp.focus({ workspace = i }))
    hl.bind(M.." + SHIFT + "..key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(M.." + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(M.." + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- ─── Locked (work over lockscreen) ────────────────────────────────────────────
local locked = {
    { M.." + J", "playerctl previous"   },
    { M.." + K", "playerctl play-pause" },
    { M.." + L", "playerctl next"       },
}
for _, b in ipairs(locked) do
    hl.bind(b[1], exec(b[2]), { locked = true })
end

-- ─── Locked + repeating (media / brightness) ──────────────────────────────────
local locked_rep = {
    -- Laptop keys.
    { "XF86AudioRaiseVolume",   "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+" },
    { "XF86AudioLowerVolume",   "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" },
    { "XF86AudioMute",          "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" },
    { "XF86AudioMicMute",       "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" },
    { "XF86MonBrightnessUp",    "brightnessctl -q s 10%+" },
    { "XF86MonBrightnessDown",  "brightnessctl -q s 10%-" },
    -- Desktop keyboard F-row volume.
    { M.." + SHIFT + F1",  "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-" },
    { M.." + SHIFT + F2",  "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+" },
    { M.." + SHIFT + F3",  "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" },
    { M.." + SHIFT + F4",  "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" },
    { M.." + SHIFT + F5",  "brightnessctl s 10%-" },
    { M.." + SHIFT + F6",  "brightnessctl s 10%+" },
}
for _, b in ipairs(locked_rep) do
    hl.bind(b[1], exec(b[2]), { locked = true, repeating = true })
end

-- ─── Information toasts (CTRL + F1~F8) ───────────────────────────────────────
local info = {
    { M.." + CTRL + F1", [[notify-send -h int:transient:1 "Current volume" "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)"%" ($3?" "$3:"")}')"]] },
    { M.." + CTRL + F2", [[notify-send -h int:transient:1 "Current time"  "$(date +%H:%M:%S)"]] },
    { M.." + CTRL + F3", [[notify-send -h int:transient:1 "Current date"  "$(date +%d.%m.%Y)"]] },
    { M.." + CTRL + F4", [[notify-send -h int:transient:1 "Brightness"    "$(brightnessctl -m | awk -F, '{print $4}')"]] },
    { M.." + CTRL + F5", [[notify-send -h int:transient:1 "GPU usage"     "$(]] .. gpu  .. [[)"]] },
    { M.." + CTRL + F6", [[notify-send -h int:transient:1 "CPU usage"     "$(top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{printf("%.0f%%",100-$1)}')"]] },
    { M.." + CTRL + F7", [[notify-send -h int:transient:1 "RAM usage"     "$(free | awk '/Mem:/{printf("%.0f%%",$3/$2*100)}')"]] },
    { M.." + CTRL + F8", [[notify-send -h int:transient:1 "Temperature"   "$(]] .. temp .. [[)"]] },
}
for _, b in ipairs(info) do
    hl.bind(b[1], exec(b[2]), { repeating = true })
end

-- ─── Alt binds ────────────────────────────────────────────────────────────────
hl.bind("ALT + tab",         exec(switcher .. " next"))
hl.bind("ALT + SHIFT + tab", exec(switcher .. " prev"))
hl.bind("ALT + CTRL + tab",  exec(switchmenu))