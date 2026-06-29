# _[MolniOS](https://codeberg.org/al1h3n/molnios-install)_ shell keybinds:

**Themes:**
- **Fish:** [Tide](https://github.com/IlanCosman/tide)
- **ZSH:** [PowerLevel10K](https://github.com/romkatv/powerlevel10k)

## Keybinds

`Shift + Right arrow` / `Shift + Tab` — accept autosuggestion.

`Ctrl + Left / Right` — move through words.<br>
`Ctrl + Shift + Left / Right` — word selection / deletion (depends on terminal emulator).

`Ctrl + R` — fuzzy history search (via fzf-fish).<br>
`Tab` — completions with preview (built-in Fish + fzf-fish / ZSH magic-space).

### Dynamic shortcuts
`Ctrl + XU` — undo.<br>
`Ctrl + Y` — redo.<br>
`Ctrl + XE` — edit command in `$VISUAL`.<br>
`Ctrl + XL` — clear screen but keep latest content scrollback.<br>
`Ctrl + XC` — copy current command buffer to clipboard.<br>
`Ctrl + XW` — generate pywal colors for an input directory.<br>
`Ctrl + XG` + `C / P / S / L` — `git commit`/`push`/`status`/`log`.

---

## Shortcuts

### Helpful
`(ZSH ONLY) NE / NO / Q` — add to the end of command to silence `stderr` / `stdout` / both.<br>
`(ZSH ONLY) J` — add to the end of command to output it to `jq`.

`c` — `clear` shortcut.<br>
`cl` — just move everything above.<br>
`ki` / `kitty` — kitty with custom config.<br>
`wez` — wezterm with custom config.<br>
`ze` — `zellij` shortcut.<br>
`duf` — `duf` custom shortcut.<br>
`reset` / `res` — reset custom terminal colors.<br>
`history clear` / `rm -f ~/.zsh_history` — clear history of commands.<br>
`mk` — `mkdir -p`.<br>
`mostwanted` — most used commands in your shell history.<br>
`httpyac` — custom `httpyac` script.

`s` — [doas](https://github.com/Duncaen/OpenDoas) — has less code than sudo, making it safer.<br>
`sud` — `su -c $@` (logins as root, sudo gives only temporary permissions).<br>
`h` / `help` — `apropos` (find commands' definitions starting from string).<br>
`k` / `pk` — `killall` / `pkill` (kill program).<br>
`q` — switch shell (from fish to zsh or vice-versa).<br>
`po` — `poweroff` (shutdown PC).<br>
`re` — `reboot`.<br>
`sl` — `sleep`.<br>
`ln` — `ln -sfn`.<br>
`rr` — **rmproved** (removes all provided files with a confirmation prompt).<br>
`ns` / `nss` — `notify-send` / temporary notification.<br>
`we` — current weather, uses [wttr.in](https://github.com/chubin/wttr.in). Use city as argument, or leave blank for local.<br>
`myip` — current location, country, coordinates, ISP and public IP.<br>
`mu` / `shazam` — custom script using _songrec_ to find the song currently playing.<br>
`f` — [Pay Respects](https://github.com/iffse/pay-respects) (write `f` after an error to get fix suggestions).<br>
`cat` — [bat](https://github.com/sharkdp/bat).<br>
`man` — [tealdeer](https://github.com/tealdeer-rs/tealdeer) — runs `tldr` first, defaults to manpage if missing.<br>
`sakura` / `sakurastatic` — cbonsai custom tree config (animated / static).<br>
`pokemon` — create random pokemon.

`co` — change terminal color scheme via [wallust](https://codeberg.org/explosion-mental/wallust).<br>
`wa` — set custom wallpaper and change terminal color scheme via [pywal16](https://github.com/eylles/pywal16).

`wifi` / `blue` / `et` — write on/off to switch Wi-Fi / Bluetooth / Ethernet.

`vq` / `vw` / `ve` / `vr` / `vt` — `warp-cli` disconnect / status / connect / reg delete / reg new.

---

### `fzf` related (dynamic lists)
`fbat` — fuzzy find file and output it via bat.<br>
`gtrack` — fuzzy find git-tracked files.<br>
`hist` — fuzzy search and execute from history list.<br>
`txt` — fuzzy find text inside files (**VERY LAGGY**).<br>
`journal` — browse all systemd logs.<br>
`proc` — process list; hit enter to kill (-9) the selected process.<br>
`en` — environment variables.<br>
`a` — alias list.<br>
`gb` — select git branch.

---

### Custom scripts
`sw` — [sweeper](https://github.com/Alihan1ai9595/sweeper) script (clean system junk).<br>
`ml` — [molnios](https://codeberg.org/al1h3n/install) script (installation tool).<br>
`gi` — `git-cooker` script made exclusively for MolniOS (AIO swizz knife for `git`).<br>
`u` — update system via molnios script.<br>
`pa` — path script (shorten paths of configurations).<br>
`m` / `my` — open main menu with Rofi/YAD.<br>
`am` — action wlogout menu.<br>
`rec` — _recording_ script (record screen).<br>
`r` — reloadus script (reload **configuration** and applications).<br>
`br` — brightness script (type value like -10%, 50%, or `-g` to get value).

---

### Commands
`lock` — `hyprlock` screen locker.<br>
`menu` — `rofi` application selection menu.<br>
`y` — terminal file manager ([yazi](https://github.com/sxyazi/yazi)).<br>
`e` — alternative terminal file manager ([superfile](https://github.com/yorukot/superfile)).<br>
`yt` — browse and play [youtube](https://github.com/Benexl/yt-x) directly from your terminal.<br>
`fa` / `fas` / `fast` — shortcuts to custom video/static [anifetch](https://github.com/Notenlish/anifetch) configurations.<br>
`nixfetch` — shortcut to custom NixOS fastfetch.<br>
`wh` / `wn` — starts [waybar](https://github.com/Alexays/Waybar) with custom configuration (hyprland/niri).<br>
`dir` | `ls` | `l` | `lt` — colorful [eza](https://github.com/eza-community/eza) command replacements with icons and tree views.

#### Connection
`lan` — connection manager (nmtui).<br>
`bt` — bluetooth connection (blueman).

#### Editing
`v` — [nvim](https://github.com/neovim/neovim) shortcut.<br>
`d` / `cfg` / `scr` — yazi shortcuts directly to dotfiles / configs / scripts.
`lh` — `ln --help`

#### [Mechabar](https://github.com/sejjy/mechabar)
`p` — power menu.<br>
`n` / `b` — network / bluetooth managers.<br>
`bu` / `bd` — backlight up / down.<br>
`vu` / `vd` — volume up / down.

---

### Arch Linux Specific
`pr` — remove orphaned packages (via `yay`).<br>
`pu` — update all packages (via `yay`).

---

### Custom Git Commands
`g` — `git --filter=blob:none --depth=1`<br>
`gbg` — `git status`<br>
`ga` — `git add`<br>
`gc` — `git commit -v` (opens editor).<br>
`gcmsg` — `git commit -m` (inline text).<br>
`gp` — `git push`<br>
`gr` — `git revert COMMIT` (revert changes).<br>
`grv` / `gra` / `grset` / `grrm` / `grmv` — `git remote` `-v` / `add` / `set-url` / `remove` / `rename`.

---

## Navigating (extreme speed)

1. Train the `zoxide` algorithm simply by moving into directories (it tracks your activity).
2. Type `cd folder1 folder2` to find the nearest match.
   *(Example: writing `~/.config/hyprland/custom/img` repeatedly means you can just type `cd hyprland img` next time!)*

**Rules:**
1. Last component must be the final folder.
2. No reversed searches (e.g., `cd img hyprland` won't work).
Or type `cd` alone to show an `fzf` picker of your most used directories.

### FAQ
- Remove a folder from tracking: `zoxide remove <dir>`
- Edit tracking list interactively: `zoxide edit`
- Restore default `cd`: remove `--cmd cd` flag from shell config.

---

## (ZSH Only) Extra Features

### zmv command
`zmv '(*).log' '$1.txt'` renames all `.log` files to `.txt`.<br>
Simpler syntax: `zmv -W '*.txt' '*.log'`
*(Use `-n` to preview changes, `-i` for interactive).*

### Bookmarking directories
Use `hash -d BOOK=~/your/folder` to bookmark a directory. Open using `~BOOK`.

---

## Technical Notes
- **Fish:** History, completions, highlighting, and autosuggestions are natively built-in (deduplicated, persistent, syntax-aware). Plugin managers aren't required as Nix manages the environment directly. `fzf-fish` effectively acts as a drop-in for `fzf-tab`.
- **ZSH:** Syntax highlighting, completions, and autosuggestions rely on Sheldon to hook `zsh-autosuggestions`, `fzf-tab`, and built-in rules (e.g. `sponge` to replace standard history-ignoring).