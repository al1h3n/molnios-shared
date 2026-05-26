# _[MolniOS](https://codeberg.org/al1h3n/molnios-install)_ Fish keybinds:

Theme: [Tide](https://github.com/IlanCosman/tide).

## Keybinds

`Shift + Right arrow` — accept autosuggestion (built-in Fish behavior).

`Ctrl + Left / Right` — move through words (built-in Fish behavior).<br>
`Ctrl + Shift + Left / Right` — word selection / deletion.

`Ctrl + R` — fuzzy history search (via fzf-fish).<br>

`Tab` — completions with preview (built-in Fish + fzf-fish).

---

## Shortcuts

### Helpful
`c` — `clear` shortcut.<br>
`cl` — just move everything above.<br>
`ki` / `kitty` — kitty with custom config.<br>
`ze` — `zellij` shortcut.<br>
`duf` — `duf` custom shortcut.<br>
`reset` — reset custom terminal colors.<br>
`history clear` — clear history of commands (only for fish).

`s` — [doas](https://github.com/Duncaen/OpenDoas) — has less code than sudo, which makes it more safe.<br>
`sud` — `su -c $@` (logins as root, sudo gives only temporary permissions).<br>
`h` / `help` — `apropos` (find commands' definitions starting from string).<br>
`k` — `killall` (kill program).<br>
`pk` — `pkill` (kill program).<br>
`q` — `fish` (switch shell).<br>
`po` — `poweroff` (shutdown PC).<br>
`re` — `reboot`.<br>
`ns` — `notify-send`.<br>
`nss` - `notify-send` (temporary notification)<br>
`sl` — `sleep`.<br>
`ln` — `ln -sfn`.<br>
`rr` — **rmproved** (removes all provided files with confirmation).<br>
`we` — current weather, uses [wttr.in](https://github.com/chubin/wttr.in). Use city/region name as argument. Uses current location when no arguments given.<br>
`myip` — current location, country, coordinates and public IP.<br>
`mu` / `shazam` — custom script which uses _songrec_ to find song you're listening to.<br>
`f` — [Pay Respects](https://github.com/iffse/pay-respects) (write after an error to fix it).<br>
`cat` — [bat](https://github.com/sharkdp/bat).<br>
`man` — [tealdeer](https://github.com/tealdeer-rs/tealdeer) — run `tldr -qu` if you can't find manual.<br>
`grep` / `rg` — [ripgrep](https://github.com/BurntSushi/ripgrep).<br>
`find` / `fd` — [fd](https://github.com/sharkdp/fd).<br>
`sakura` — cbonsai custom config.<br>
`sakurastatic` — same but without animations.<br>
`pokemon` - create random pokemon.<br>

`co` — change terminal color scheme via [wallust](https://codeberg.org/explosion-mental/wallust).<br>
`wa` — set custom wallpaper and change terminal color scheme via [pywal16](https://github.com/eylles/pywal16).<br>

`wifi` — write on/off to switch Wi-Fi.<br>
`blue` — write on/off to switch Bluetooth.<br>
`et` — write on/off to switch Ethernet.<br>

`vq` — `warp-cli disconnect`<br>
`vw` — `warp-cli status`<br>
`ve` — `warp-cli connect`<br>
`vr` — `warp-cli registration delete`<br>
`vt` — `warp-cli registration new`<br>

---

### `fzf` related (dynamic lists)
Apparently `fzf-fish` is smarter than `zsh` one, but doesn't have `--placeholder` argument.
`fbat` — find file and output it.<br>
`gtrack` — find tracked files.<br>
`hist` — view history list.<br>
`txt` — find text in files (**VERY LAGGY**).<br>
`journal` — all system logs.<br>
`proc` — process list; if enter is hit, process will be terminated.<br>
`en` — environment variables.<br>
`a` — alias list.<br>
`gb` — select git branch.

---

### Custom scripts
`sw` — [sweeper](https://github.com/Alihan1ai9595/sweeper) script (use to clean system).<br>
`u` — [molnios](https://codeberg.org/al1h3n/install) script (installation/updating system).<br>
`pa` — path script (use to shorten paths of configurations).<br>
`m` / `my` — open main menu with Rofi/YAD.<br>
`am` — action wlogout menu.<br>
`rec` — _recording_ script (record your screen).<br>
`r` — reloadus script (reload **configuration** and applications).<br>

---

### Commands
`lock` = `hyprlock -q -c $conf/hypr/hyprlock` — enables lock screen.<br>
`menu` = `rofi -config $conf/rofi.rasi -show drun &>/dev/null` — starts application selection menu.<br>
`y` — starts terminal file manager ([yazi](https://github.com/sxyazi/yazi)).<br>
`e` — alternative — [superfile](https://github.com/yorukot/superfile).<br>
`yt` — browse [youtube](https://github.com/Benexl/yt-x) from your terminal.<br>
`fa` — shortcut to custom [anifetch](https://github.com/Notenlish/anifetch) configuration (video).<br>
`fas` — shortcut to custom [fastfetch](https://github.com/fastfetch-cli/fastfetch) configuration (static image).<br>
`fast` — shortcut to custom [anifetch](https://github.com/Notenlish/anifetch) configuration (write path to show your own video).<br>
`wh` / `wn` — starts [waybar](https://github.com/Alexays/Waybar) with custom configuration (hyprland/niri).<br>
`dir` | `ls` | `l` — colorful [ls](https://github.com/eza-community/eza) command. `lt` — tree view with icons.

#### Connection
`lan` — connection manager (nmtui).<br>
`bt` — bluetooth connection (blueman).

#### Editing (nvim)
`v` — [nvim](https://github.com/neovim/neovim) shortcut.<br>
`d` — open dotfiles root directory.<br>
`cfg` — open config dir.<br>
`scr` — open scripts dir.<br>

#### Misc
`lh` — `ln --help`

#### [Mechabar](https://github.com/sejjy/mechabar)
`p` — power menu.<br>
`n` — network manager.<br>
`b` — bluetooth manager.<br>
`bu` / `bd` — backlight up/down.<br>
`vu` / `vd` — volume up/down.

---

### Arch Linux
`pr` — remove orphaned packages (via `yay`).<br>
`pu` — update all packages (via `yay`).

---

### Custom git commands
`g` — `git --filter=blob:none --depth=1`<br>
`gbg` — `git status`<br>
`ga` — `git add`<br>
`gc` — `git commit -v` (opens editor where you type your commit).<br>
`gcmsg` — `git commit -m` (type your own text).<br>
`gp` — `git push`<br>

`gra` — `git remote add`<br>
`grset` — `git remote set-url`<br>
`grrm` — `git remote remove`<br>
`grmv` — `git remote rename`<br>

---

## Navigating (extreme speed)

1. Train zoxide algorithm by moving into directories as always (it'll track your activity).
2. Type `cd folder1 folder2` to find nearest folder to your path.

It will work like this: you wrote 95 times `~/.config/hyprland/custom/img`,
next `cd hyprland img` will switch you to the directory!

### Rules
1. Last component must be the final folder.
2. No reversed search like `cd img hyprland`.

Or use it with `fzf`: type `cd` alone to show fuzzy picker of most used directories.

### FAQ
To remove a folder: `zoxide remove <dir>`<br>
To edit interactively: `zoxide edit`<br>
To restore default `cd` behavior: remove `--cmd cd` flag in `config.fish`.

---

## Notes

- Based on previous ZSH config. Both will receive same updates, keybinds and documentation.
- Fish has **no plugin manager** — plugins are managed by **Nix** directly. That said, this is the reason why it's faster.
- Fish history is **built-in** — automatic deduplication, persistent, no config needed.
- Fish **completions** are **built-in** — no `compinit` needed.
- ZSH syntax highlighting is replaced by **Fish's built-in highlighting**.
- ZSH autosuggestions are replaced by **Fish's built-in autosuggestions**.
- `fzf-fish` plugin replaces `fzf-tab` and `fzf --zsh`.
- `autopair` plugin replaces ZSH bracket auto-closing.
- `sponge` plugin replaces `hist_ignore_all_dups` / `hist_ignore_space` behavior.
- Tide theme is configured once via `tide configure` command (see `config.fish` section 10).