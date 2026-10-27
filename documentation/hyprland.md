# *[MolniOS](https://codeberg.org/al1h3n/molnios-install)* hyprland keybinds (in nutshell, as easy as possible)

## Keybind layout logic (in nutshell, not exact)
- `QWER` → launching / execution
- `ASDF` → main apps
- `ZXCV` → system actions
- `Shift` → "move / alternative"
- `Ctrl` → "info / system"

### Keybinds

#### Basics
`Super` - `Windows` / `Command` key on your keyboard.<br>
`Super + Space` - switch keyboard layout (by default US/RU, you can change it in config).<br>
`Caps Lock` = control.<br>
`Alt + Tab` / `Alt + Shift + Tab` - window switcher<br>
`Alt + Ctrl + Tab` - window switcher (application menu).<br>

#### Media
`Print` - make *screenshot* and launch manager.<br>
`Super + Print` - **record** screen.<br>
`Super + Insert` - OCR (no UI).<br>

#### Screen capture & advanced tools
`Super + Shift + Print` → Record with audio<br>
`Super + Ctrl + Print ` → Alternative recording mode (OBS)<br>
`Super + Alt + Print`   → OCR (extract text from image)<br>

#### Action menu
`Super + End` → Open power menu (wlogout).<br>

#### Apps & workspace shortcuts
`Super + Q` → Terminal<br>
`Super + W` → Free window mode<br>
`Super + E` → File manager<br>
`Super + R` → Application launcher<br>
`Super + T` → Command runner<br>
`Super + Y` → Run virtual manager<br>
`Super + P` → Private workspace<br>

#### App shortcuts
`Super + A` → Notes (priority: Notion → Obsidian → AppFlowy)<br>
`Super + S` → Browser (priority: Firefox → Brave → Ungoogled Chromium → Chromium → Chrome)<br>
`Super + D` → Show desktop<br>
`Super + F` → Fullscreen<br>
`Super + G` → Discord (priority: Vesktop → Webcord → Discord)<br>
`Super + H` → Telegram (priority: 64Gram → Kotatogram → Ayugram → Telegram Desktop)<br>

#### Media controls
`Super + J` → Previous track<br>
`Super + K` → Play / pause<br>
`Super + L` → Next track<br>

#### System controls
`Super + Z` → Exit Hyprland<br>
`Super + C` → Close active window<br>
`Super + V` → Clipboard manager<br>

#### Tools & utilities
`Super + X` → Emoji picker<br>
`Super + B` → OCR (advanced, language selection)<br>

#### Sleep
`Super + Escape` - hibernate.<br>
`Super + Shift + Escape` - lock screen.<br>

#### Window management & workspace controls
`Super + Shift + Q` → zellij (terminal multiplexer).<br>
`Super + Shift + W` → Switch window layout axis.<br>
`Super + Shift + E` → yazi (explorer CLI).<br>
`Super + Shift + R` → Reload wallpaper (supports awww, mpvpaper & waypaper).<br>
`Super + Shift + T` → Freeze a wayland game.<br>
`Super + Shift + P` → Move window to private workspace.<br>

#### Window movement
`Super + Shift + A` → Move window left.<br>
`Super + Shift + S` → Move window up.<br>
`Super + Shift + D` → Move window down.<br>
`Super + Shift + F` → Move window right.<br>

#### Tools & system
`Super + Shift + G` → Open wallpaper engine.<br>
`Super + Shift + H` → Gamemode toggle.<br>

#### Applications
`Super + Shift + Z` → Coding app (priority: VSCodium, VSCode, Cursor, default coder defined in `hyprconfig`).<br>
`Super + Shift + X` → Spotify.<br>
`Super + Shift + C` → MPV (media player).<br>

#### System utilities
`Super + Shift + V` → Bluetooth manager.<br>
`Super + Shift + B` → Network manager.<br>

#### Audio controls
`Super + Shift + F1` → Volume up.<br>
`Super + Shift + F2` → Volume down.<br>
`Super + Shift + F3` → Mute audio.<br>
`Super + Shift + F4` → Mute microphone.<br>

#### Brightness controls
`Super + Shift + F5` → Brightness up.<br>
`Super + Shift + F6` → Brightness down.<br>

#### Audio & system status
`Super + Ctrl + F1` → Show volume level.<br>
`Super + Ctrl + F2` → Show current time.<br>
`Super + Ctrl + F3` → Show current date.<br>

#### Hardware monitoring
`Super + Ctrl + F4` → Show brightness value.<br>
`Super + Ctrl + F5` → Show GPU usage.<br>
`Super + Ctrl + F6` → Show CPU usage.<br>
`Super + Ctrl + F7` → Show RAM usage.<br>
`Super + Ctrl + F8` → Show temperature.<br>

#### Window - extra
`Super + Alt + Q` - Do not stretch window (pseudo / no resize behavior).<br>

#### Eyedropper and everything related to colors
`Super + Alt + Z` - open eyedropper.<br>
`Super + Alt + X` - open eyedropper's hostory.<br>

#### Ctrl keybinds
`Super + Ctrl + Z` - reload all configurations.<br>
`Super + Ctrl + P` - move from private workspace.<br>

### Other
`Super + grave` - Open text editor (`neovim` btw).
`Super + Shift + grave` - Main menu.

### Out-of-box keybinds (hyprland basics)
`Super + x, where x is 0~9` - move to workspaces.<br>
`Super + Shift + x, where x is 0~9` - move window to particular one.<br>
`Super + arrows` - switch to window.<br>
`Super + Shift + arrow up/down` - zoom/unzoom.<br>

### Default keybinds: mouse
`Super + mouse wheel` - move through workspaces.<br>
`Super + LMB/RMB` - drag/size windows.<br>

### Laptop keybinds
Laptop multimedia keys for volume and LCD brightness are included.<br>
Try it by yourself!<br>

### Hypr3D: 3D workspace
[Hypr3D](https://github.com/samine825/Hypr3D) lets you walk or fly around your windows in a 3D scene.<br>

#### Workspace, scenes & flight
`Super + F12` → Toggle the 3D workspace.<br>
`Super + F6` / `Super + F7` → Previous / next scene.<br>
`Super + F8` → Reload the current scene and return to its spawn point.<br>
`Super + F10` → Toggle flying / walking (collisions stay enabled outside inspection mode).<br>
`Super + F11` → Toggle inspection mode: fly through walls and floors. Toggle off to restore collisions and your selected flying / walking mode.<br>

Flight starts with the scene's default. Reloading the config, switching scenes or resetting a scene restores that default and exits inspection mode. Closing and reopening 3D keeps your movement mode.<br>

#### Movement & camera (while in 3D movement mode)
Mouse movement → Look around.<br>
`W / A / S / D` → Move forward / left / backward / right.<br>
`Space` → Rise while flying; jump while walking.<br>
`Shift` → Descend while flying.<br>
Hold `Ctrl` (or `Caps Lock`) → Sprint (2.5× speed).<br>
Hold `C` → Zoom the camera; use the mouse wheel to adjust zoom. Release `C` to return to normal.<br>
`F3` → Toggle debug information and collision wireframe (also works in window-input mode).<br>
`F5` → Switch between first-person, third-person rear and third-person front views.<br>
`Super + Left Alt` → Switch between movement and window-input mode. Window-input mode frees the cursor and lets you type in the focused window; toggle again to resume moving.<br>

#### Windows in 3D
Aim at a window to interact with it. In window-input mode, use the free cursor to click, scroll and type.<br>
`Super + LMB` + mouse movement → Drag the window.<br>
`Super + RMB` + mouse movement → Resize the window.<br>
`Super + middle mouse button` + mouse movement → Rotate the window.<br>
`Super + mouse wheel` → Move the window closer / farther.<br>

See [the advanced Hypr3D controls section](hyprland-advanced.md#hypr3d-3d-workspace-controls) for the full reference. Configure custom binds in [`config/hyprland/modules/hypr3d.lua`](../config/hyprland/modules/hypr3d.lua).<br>

## Editing
Everything can be changed in `hyprconfig` file. Just locate section `Keybinds` and change letters in binds!<br>

P.S: tried to make this documentation as understandable as possible :)<br>
