# _[MolniOS](https://codeberg.org/al1h3n/molnios-install)_ Niri keybinds:
`Caps Lock` = control.<br>
`Alt [Shift] + Tab` - next and previous window switch, `Alt + Ctrl + Tab` - window menu switcher (advanced).<br>

#### Media
`PrintScreen` - make _screenshot_ and launch manager.<br>
`Super + PrintScreen` - __record__ screen.<br>
`Super + Insert` - OCR - copy text (no UI).<br>
`Ctrl + PrintScreen` - Native Niri screenshot with __cursor__ pointer included.<br>

#### Media: advanced
`Super + Shift/Ctrl + PrintScreen` - record screen with _audio_ or via __OBS__.<br>

#### Menus
`Super + End` - [wlogout](https://github.com/ArtsyMacaw/wlogout) action menu.<br>
`Super + Shift + /` - Show Niri important hotkeys overlay.<br>

#### Top keybinds (Q~P) - running system applications and switching window mode
`Super + Space` - switch keyboard layout (by default US/RU).<br>

`Super + Q/W/E/R/T/Y/P` - terminal, toggle __floating__ window mode, file manager, run application, run command, open virtual manager, __merge/expel__ window into column.<br>
`Super + A/S/D/F/G/H; J/K/L` -  notes, browser, toggle __overview__ (show desktop equivalent), full screen, discord, telegram; _previous_ song, __pause|unpause__, _next_ song.<br>
`Super + Z/X/C/V/B` - exit niri, emoji picker, close window, clipboard manager, OCR advanced (with language selection).

`Super + Escape` - hibernate. `Super + Shift + Escape` - lock screen (hyprlock).<br>
`Super + Shift + Q/W/E/R` - terminal multiplexer [zellij](https://github.com/zellij-org/zellij), toggle __tabbed__ column display, yazi, switch preset window height.<br>
`Super + Shift + A/S/D/F; G/C` - move window/column to specified location (left column, up window, down window, right column). Gamemode, MPV player. <br>
`Super + Ctrl + F1/2/3/5/8` - show volume level, time, date, GPU load, temperature.

## Other keybinds
`Super + grave` - editor (nvim).
`Super + Shift + grave` - main menu.

## Out-of-box keybinds (Niri basics)
`Super + x, x[1-9]` - workspaces. `Super + Shift + x, x[1-9]` - move window to particular one.<br>
`Super + arrows` - switch to window/column (Left/Right moves between columns, Up/Down moves within a column).<br>

## Default keybinds: mouse
`Super + mouse wheel` - move through workspaces.<br>

## Laptop keybinds
Laptop multimedia keys for volume and LCD brightness are included and work even when the screen is locked!

#### Facts
- Niri is a scrollable-tiling Wayland compositor. Windows are arranged in columns on an infinite strip going to the right. Opening a new window never causes existing windows to resize!
- Niri 26.04 natively blurs transparent context menus and layer-shell interfaces out-of-the-box.