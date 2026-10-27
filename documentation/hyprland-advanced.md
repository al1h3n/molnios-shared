# *[MolniOS](https://codeberg.org/al1h3n/molnios-install)* hyprland keybinds:
`Caps Lock` = control.<br>
`Alt [Shift] + Tab` - next and previous window switch , `Alt + Ctrl + Tab` - window menu switcher (advanced).<br>

#### Media
`PrintScreen` - make *screenshot* and launch manager.<br>
`Super + PrintScreen` - **record** screen.<br>
`Super + Insert` - OCR - copy text (no UI).<br>

#### Media: advanced
`Super + Shift/Ctrl/Alt + PrintScreen` - record screen with *audio* or via **OBS**, use **OCR** (image to text).<br>

#### Menus
`Super + End` - [wlogout](https://github.com/ArtsyMacaw/wlogout) action menu.<br>

#### Top keybinds (Q~P) - running system applications and switching window mode
`Super + Space` - switch keyboard layout (by default US/RU).<br>


`Super + Q/W/E/R/T/Y/P` - terminal, **free** window mode, file manager, run application, run command, open virtual manager private workspace.<br>
`Super + A/S/D/F/G/H; J/K/L` -  notes, browser, show desktop, full screen, discord, telegram; *previous* song, **pause|unpause**, *next* song.<br>
`Super + Z/X/C/V/B` - exit hyprland, emoji picker, close, clipboard manager, OCR advanced (with language selection).

`Super + Escape` - hibernate. `Super + Shift + Escape` - lock screen (hyprlock).<br>
`Super + Shift + Q/W/E/R/T/P` - terminal multiplexer [zellij](https://github.com/zellij-org/zellij), **switch** window axis, yazi, reload wallpaper, freeze a wayland game, move to private workspace.<br>
`Super + Shift + A/S/D/F; G/H` - move window to specified location (left, up, down, right). Open wallpaper *engine*, gamemode. <br>
`Super + Shift + Z/X/C/V/B` - open Coding app/Spotify/MPV/bluetooth/network manager.<br>
`Super + Shift + F1/2/3/4/5/6` - **volume** up/down/mute, mute microphone, turn **brightness** up/down.<br>
`Super + Ctrl + F1/2/3/4/5/6/7/8/9` - show volume level, time, date, brighness value, GPU/CPU/RAM/Disk load, temperature.

`Super + Alt + Q` - **do not stretch window**.<br>
`Super + Alt + Z/X` - open eyedropper, open eyedropper history.

`Super + Ctrl + Z/X` - reload all configurations.<br>
`Super + Ctrl + P` - move from private workspace.

## Other keybinds
`Super + grave` - editor (nvim).
`Super + Shift + grave` - main menu.
`Ctrl + Shift + Esc` - `btop`.

## Out-of-box keybinds (hyprland basics)
`Super + x, x[0-9]` - workspaces. `Super + Shift + x, x[0-9]` - move window to particular one.<br>
`Super + arrows` - switch to window.<br>
`Super + Shift + arrow up/down` - zoom/unzoom.

## Default keybinds: mouse
`Super + mouse wheel` - move through workspaces.<br>
`Super + LMB/RMB` - drag/size windows.

## Laptop keybinds
Laptop multimedia keys for volume and LCD brightness are included.

## Hypr3D: 3D workspace controls
[Hypr3D](https://github.com/samine825/Hypr3D) turns the workspace into a walkable 3D scene.
Custom binds are configured in [`config/hyprland/modules/hypr3d.lua`](../config/hyprland/modules/hypr3d.lua).

### Workspace, scenes and flight
| Bind | Action |
| --- | --- |
| `Super + F12` | Toggle the 3D workspace. |
| `Super + F6` | Load the previous scene. |
| `Super + F7` | Load the next scene. |
| `Super + F8` | Reload the current scene and reset the player to its spawn point. |
| `Super + F10` | Toggle flying / walking; collisions stay enabled outside inspection mode. |
| `Super + F11` | Toggle inspection mode: fly through walls and floors (no collision). Toggle off to restore collision and the selected flying / walking mode. |

Flight starts with the scene's default. Reloading the config, switching scenes or resetting a scene restores that default and exits inspection mode. Closing and reopening the 3D workspace keeps the current movement mode.

### Movement and camera
These controls are built into the plugin and work while the 3D workspace is open in movement mode.

| Input | Action |
| --- | --- |
| Mouse movement | Look around. |
| `W / A / S / D` | Move forward / left / backward / right. |
| `Space` | Rise while flying; jump while walking. |
| `Shift` | Descend while flying. |
| Hold `Ctrl` (or remapped `Caps Lock`) | Sprint (2.5× movement speed). |
| Hold `C` | Zoom the camera; release to return to normal. |
| Mouse wheel while holding `C` | Adjust camera zoom. |
| `F3` | Toggle the debug HUD and collision wireframe (also works in window-input mode). |
| `F5` | Cycle first-person, third-person rear and third-person front views. |
| `Super + Left Alt` | Toggle movement / window-input mode. Window-input mode sends keys to the focused window and frees the mouse cursor; toggle again to resume moving. |

### Windows in 3D
Aim at a window to interact with it. In window-input mode, use the free cursor to click, scroll and type in applications.

| Input | Action |
| --- | --- |
| `Super + LMB` + mouse movement | Drag the window. |
| `Super + RMB` + mouse movement | Resize the window. |
| `Super + middle mouse button` + mouse movement | Rotate the window. |
| `Super + mouse wheel` | Move the window closer / farther (window zoom). |

#### Facts
- You can't change XWayland state in `hyprctl`.
