# _[MolniOS](https://codeberg.org/al1h3n/molnios-install)_ Niri keybinds:
`Caps Lock` = control.<br>
`Main` = `Super` / `Alt` (when launching from other WM/DE).<br>
`Alt [Shift] + Tab` - next and previous window switch, `Alt + Ctrl + Tab` - window menu switcher (advanced).<br>

#### Media
`PrintScreen` - make _screenshot_ and launch manager.<br>
`Main + PrintScreen` - __record__ screen.<br>
`Main + Insert` - OCR - copy text (no UI).<br>
`Ctrl + PrintScreen` - Native Niri screenshot with __cursor__ pointer included.<br>

#### Media: advanced
`Main + Shift/Ctrl + PrintScreen` - record screen with _audio_ or via __OBS__.<br>

#### Menus
`Main + End` - [wlogout](https://github.com/ArtsyMacaw/wlogout) action menu.<br>
`Main + Shift + /` - Show Niri important hotkeys overlay.<br>

#### Top keybinds (Q~P) - running system applications and switching window mode
`Main + Space` - switch keyboard layout (by default US/RU).<br>

`Main + Q/W/E/R/T/Y/P` - terminal, toggle __floating__ window mode, file manager, run application, run command, open virtual manager, __merge/expel__ window into column.<br>
`Main + A/S/D/F/G/H; J/K/L` -  notes, browser, toggle __overview__ (show desktop equivalent), full screen, discord, telegram; _previous_ song, __pause|unpause__, _next_ song.<br>
`Main + Z/X/C/V/B` - exit niri, emoji picker, close window, clipboard manager, OCR advanced (with language selection).

`Main + Escape` - hibernate. `Main + Shift + Escape` - lock screen (hyprlock).<br>
`Main + Shift + Q/W/E/R` - terminal multiplexer [zellij](https://github.com/zellij-org/zellij), toggle __tabbed__ column display, yazi, switch preset window height.<br>
`Main + Shift + A/S/D/F; G/C` - move window/column to specified location (left column, up window, down window, right column). Gamemode, MPV player. <br>
`Super + Shift + Z/X/C/V/B` - open Coding app/Spotify/MPV/bluetooth/network manager.<br>
`Main + Ctrl + F1/2/3/5/8` - show volume level, time, date, GPU load, temperature.

## Other keybinds
`Main + grave` - editor (nvim).
`Main + Shift + grave` - main menu.
`Ctrl + Shift + Esc` - `btop`.

## Out-of-box keybinds (Niri basics)
`Main + x, x[1-9]` - workspaces. `Main + Shift + x, x[1-9]` - move window to particular one.<br>
`Main + arrows` - switch to window/column (Left/Right moves between columns, Up/Down moves within a column).<br>

## Default keybinds: mouse
`Main + mouse wheel` - move through workspaces.<br>

## Laptop keybinds
Laptop multimedia keys for volume and LCD brightness are included and work even when the screen is locked!

#### Facts
- Niri is a scrollable-tiling Wayland compositor. Windows are arranged in columns on an infinite strip going to the right. Opening a new window never causes existing windows to resize!
- Niri 26.04 natively blurs transparent context menus and layer-shell interfaces out-of-the-box.