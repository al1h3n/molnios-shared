# _[MolniOS](https://codeberg.org/al1h3n/install)_ ZSH keybinds:

`Shift / right arrow` - accept autosuggestion.

`Shift + arrows` - move through words.<br>
`Ctrl + Shift + arrows` - words selection.

### Shortcuts

#### Helpful
`c` - `clear` shortcut.<br>
`cl` - just move everything above.

`text` - `nvim -y` (neovim for newbies instead of nano or micro)<br>
`s` - `sudo`<br>
`k`- `killall` (kill program)<br>
`q` - `zsh` (shell)<br>
`po` - `poweroff` (shutdown PC)<br>
`re` - `reboot`<br>
`ns` - `notify-send`<br>
`sl` - `sleep`<br>
`ln` - `ln -sfn`<br>
`rr` - __rmproved__ (removes all provided files in list)

#### Custom scripts
`sw` - [sweeper](https://github.com/Alihan1ai9595/sweeper) script. (use to clean system)<br>
`ml` - [molnios](https://codeberg.org/al1h3n/install) script. (installation/updating system)<br>
`pa` - path script. (use to shorten paths of configurations)

`rec` - _recording_ script (record your screen)<br>
`r` - reloadus script. (reload __configuration__ and applications)

#### Commands
`lock` = `hyprlock -q -c $conf/hyprlock` - enables lock screen.<br>
`menu` = `rofi -config $conf/rofi -show drun &>/dev/null` - starts application selection menu.<br>
`y` - starts terminal file manager ([yazi](https://github.com/sxyazi/yazi))<br>
`yt` - browse [youtube](https://github.com/Benexl/yt-x) from your terminal. (watch, download videos and not only)<br>
`f` - shortcut to custom [fastfetch](https://github.com/fastfetch-cli/fastfetch) configuration.<br>
`wb` - starts [waybar](https://github.com/Alexays/Waybar) with custom configuration.<br>
`dir` | `ls` | `l` - colorful [ls](https://github.com/eza-community/eza) command. `lt` - tree view [ls](https://github.com/eza-community/eza) command with icons.

##### Connection
`lan` - connection manager. (nmtui)
`bt` - bluetooth connection. (blueman)

##### Editing (nvim)
`d` - open dotfiles root directory.
`cfg` - open config dir.
`scr` - open scripts dir.

##### Misc
`lh` - `ln --help`

##### [Mechabar](https://github.com/sejjy/mechabar)
`p` - power menu.
`uu` - update manager.
`n` - network manager.
`b` - bluetooth manager.