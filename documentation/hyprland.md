# _[MolniOS](https://codeberg.org/al1h3n/molnios-install)_ hyprland keybinds (in nutshell, as easy as possible)

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
`Print` - make _screenshot_ and launch manager.<br>
`Super + Print` - __record__ screen.<br>
`Super + Insert` - OCR (no UI).<br>

#### Screen capture & advanced tools
`Super + Shift + Print` → Record with audio<br>
`Super + Ctrl + Print ` → Alternative recording mode (OBS)<br>
`Super + Alt + Print`   → OCR (extract text from image)<br>

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
`Super + Shift + Q` → Do not stretch window (pseudo / no resize behavior).<br>
`Super + Shift + W` → Switch window layout axis.<br>
`Super + Shift + E` → Open text editor (neovim btw).<br>
`Super + Shift + R` → Reload wallpaper (supports awww, mpvpaper & waypaper).<br>
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

#### Eyedropper and everything related to colors
`Super + Alt + Z` - open eyedropper.<br>
`Super + Alt + X` - open eyedropper's hostory.<br>

#### Other
`Super + Ctrl + Z` - reload all configurations.<br>
`Super + Ctrl + X` - open main menu.<br>
`Super + Ctrl + P` - move from private workspace.<br>

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

## Editing
Everything can be changed in `hyprconfig` file. Just locate section `Keybinds` and change letters in binds!<br>

P.S: tried to make this documentation as understandable as possible :)<br>