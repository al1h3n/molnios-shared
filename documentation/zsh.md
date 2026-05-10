# _[MolniOS](https://codeberg.org/al1h3n/molnios-install)_ ZSH keybinds:

`Shift / right arrow` - accept autosuggestion.

`Shift + arrows` - move through words.<br>
`Ctrl + Shift + arrows` - words selection.

### Shortcuts

#### Helpful
`c` - `clear` shortcut.<br>
`cl` - just move everything above.

`s` - `sudo`<br>
`k`- `killall` (kill program)<br>
`q` - `zsh` (shell)<br>
`po` - `poweroff` (shutdown PC)<br>
`re` - `reboot`<br>
`ns` - `notify-send`<br>
`sl` - `sleep`<br>
`ln` - `ln -sfn`<br>
`rr` - __rmproved__ (removes all provided files in list)<br>
`we` - current weather, uses [wttr.in](https://github.com/chubin/wttr.in) data. Use city/region name as an argument (any case). Uses current location when no arguments are given.<br>
`myip` - current location, country, coordinates and public IP.<br>
`mu` / `shazam` - custom script which uses _songrec_ to find song you're listening.<br>
`f` - [Pay Respects](https://github.com/iffse/pay-respects) (write after you made an error to fix it)<br>
`cat` - [bat](https://github.com/sharkdp/bat)<br>
`man` - [tealdeer](https://github.com/tealdeer-rs/tealdeer) - run `tldr -qu` if you can't find manual.<br>
`grep` / `rg` - [ripgrep](https://github.com/sharkdp/bat)<br>
`find` / `fd` - [fd](https://github.com/sharkdp/fd)<br>
`sakura` - cbonsai custom config.<br>
`sakurastatic` - same but without animations.<br>

`wifi` - write on/off to switch Wi-Fi.<br>
`blue` - write on/off to switch Bluetooth.<br>
`et` - write on/off to switch Ethernet.<br>

`vq` - `warp-cli disconnect`<br>
`vw` - `warp-cli status`<br>
`ve`- `warp-cli connect`<br>
`vr` - `warp-cli registration delete`<br>
`vt` - `warp-cli registration new`<br>

#### `fzf` related (dynamic lists)
`fbat` - find file and output it.<br>
`gtrack` - find tracked files.<br>
`hist` - view history list.<br>
`txt` - find text in files (__VERY LAGGY__)<br>
`journal` - all system logs.<br>
`proc` - proccess list; if enter is hit, process will be terminated.<br>
`en`- environment variables.<br>
`a` - alias variables.<br>
`gb`- select git branch.

#### Custom scripts
`sw` - [sweeper](https://github.com/Alihan1ai9595/sweeper) script. (use to clean system)<br>
`ml` - [molnios](https://codeberg.org/al1h3n/install) script. (installation/updating system)<br>
`pa` - path script. (use to shorten paths of configurations).<br>
`m` / `my` - open main menu with Rofi/YAD.<br>
`am` - action wlogout menu.<br>
`rec` - _recording_ script (record your screen).<br>
`r` - reloadus script. (reload __configuration__ and applications).<br>

#### Commands
`lock` = `hyprlock -q -c $conf/hyprlock` - enables lock screen.<br>
`menu` = `rofi -config $conf/rofi -show drun &>/dev/null` - starts application selection menu.<br>
`y` - starts terminal file manager ([yazi](https://github.com/sxyazi/yazi))<br>
`yt` - browse [youtube](https://github.com/Benexl/yt-x) from your terminal. (watch, download videos and not only)<br>
`fa` - shortcut to custom [anifetch](https://github.com/Notenlish/anifetch) configuration (video).<br>
`fas` - shortcut to custom [fastfetch](https://github.com/fastfetch-cli/fastfetch) configuration (static image).<br>
`fast` - shortcut to custom [anifetch](https://github.com/Notenlish/anifetch) configuration (write path to show your own video).<br>
`wh` / `wn` - starts [waybar](https://github.com/Alexays/Waybar) with custom configuration (hyprland/niri).<br>
`dir` | `ls` | `l` - colorful [ls](https://github.com/eza-community/eza) command. `lt` - tree view [ls](https://github.com/eza-community/eza) command with icons.

##### Connection
`lan` - connection manager. (nmtui)<br>
`bt` - bluetooth connection. (blueman)

##### Editing (nvim)
`nv` - [nvim](https://github.com/neovim/neovim) shortcut.
`d` - open dotfiles root directory.<br>
`cfg` - open config dir.<br>
`scr` - open scripts dir.<br>
`e` - [superfile](https://github.com/yorukot/superfile)

##### Misc
`lh` - `ln --help`

##### [Mechabar](https://github.com/sejjy/mechabar)
`p` - power menu.
`uu` - update manager.
`n` - network manager.
`b` - bluetooth manager.

### Navigating (extreme speed).
1. Train zoxide alrorithm by moving into directories as always (it'll check your activity).
2. Type `cd folder1 folder2` to find nearest folder to your path.<br>
It will work like this: you wrote 95 times `~/.config/hyprland/custom/img`, next `cd hyprland img` will switch you to the directory!
#### Rules:
1. Last component must be final folder.
2. No reversed search like `cd img hyprland`.<br>
Or use it with `fzf`: `cd` (most used directories, use `Ctrl+P/N` to navigate).<br>
Example: `cd hyprland` will show fzf window with directories.
#### FAQ:
To remove folder type `zoxide remove <dir>`, `zoxide edit` will open interactive window.<br>
To change `cd` back again to default `z/zi` remove `--cmd cd` flag in `.zshrc` file.