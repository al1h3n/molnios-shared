# ==========================================================
# zshconfig sheldon edition.
# Used powerlevel10k theme.
# ==========================================================

# Temp files will be saved in ~/.cache/zsh, ~/.zsh_history
# .zshenv is used for non interactive actions, .zshrc only when user opens terminal interactively.

# Pokemons.
pokemon-colorscripts -r

# Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]];then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Terminal colors. "reset" to bring back to normal.
_tc_state="${XDG_CACHE_HOME:-$HOME/.cache}/molnios/colors"
if [[ -f "$_tc_state" ]]; then
  _tc_seq="$(cat "$_tc_state" 2>/dev/null)"
  if [[ -f "$_tc_seq" ]]; then
    (cat "$_tc_seq" 2>/dev/null &)

    # Source the matching colors.sh for shell variable access ($color0…$color15)
    _tc_colors="${_tc_seq%/sequences}/colors.sh"
    [[ -f "$_tc_colors" ]] && source "$_tc_colors"
    unset _tc_colors
  fi
  unset _tc_seq
fi
unset _tc_state

# 0. Variables.
EDITOR=nvim
VISUAL=nvim # codium
PHOTO=feh
MEDIA=mpv
COMPRESSOR=peazip
sharel=~/.local/share
bin=/usr/local/bin

dir="$sharel/molnios"
scripts=$dir/scripts
conf=$dir/config

# ZSH history.
HISTSIZE=20000
SAVEHIST=$HISTSIZE
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE # Use spacebar to prevent unimportant commands to be written.
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

setopt AUTOCD # Type just path.
setopt NUMERIC_GLOB_SORT # Sort by numbers.

compdef eza=ls # Set autocompletion for ls to eza.

# 1. Plugin manager (Sheldon)
if command -v sheldon &>/dev/null;then
  if [[ -f /etc/arch-release ]];then
			eval "$(sheldon source --profile arch)"
	else
			eval "$(sheldon source)"
	fi
else
  echo "ERROR: Sheldon is not installed."
fi

autoload zmv

# 5. Functions and custom commands.

exists(){
	command -v "$1" &>/dev/null
}

# Clear everything or just move above.
alias c='printf "\e[H\e[3J"'
alias cl='printf "\e[H\e[22J"'

# Output.
alias -g Q='>/dev/null 2>&1'
alias -g NE='2>/dev/null'
alias -g NO='>/dev/null'
alias -g J='| jq'

# Helpful.
alias res="reset"
alias mk="mkdir -p"
alias h="apropos"
alias help="apropos"
alias s="doas"
alias duf="duf --only local"
alias sud="su -c"
alias g="git --filter=blob:none --depth=1"
alias k="killall"
alias pk="pkill"
alias q="fish"
alias re="reboot"
alias sl="sleep"
alias ln="ln -sfn"
alias ki="kitty -c $conf/kitty.conf"
alias kitty="kitty -c $conf/kitty.conf"
alias wez="wezterm --config-file $conf/wezterm/wezterm.lua"
alias ze="zellij -c $conf/zellij/config.kdl"
alias mostwanted="fc -ln 1 | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 15"

rr(){ # rm-improved
  # 1. Check if files were actually passed to the command
  if [ $# -eq 0 ];then
    echo "Usage: rr <files>"
    return 1
  fi

  # 2. Prompt the user.
  # "$*" shows the list of files you are about to delete
  read "reply?Do you want to run rm -rf $* [y/n]? "

  # 3. Check if the answer is 'y' or 'Y'
  if [[ "$reply" =~ ^[Yy]$ ]];then
    sudo rm -rf $@
  else
    echo "\nCancelled."
  fi
}

alias vq="warp-cli disconnect"
alias vw="warp-cli status"
alias ve="warp-cli connect"
alias vr="warp-cli registration delete"
alias vt="warp-cli registration new"

alias sw="sh $bin/sweeper.sh"
alias ml="sh $bin/molnios.sh"
alias gi="sh $bin/gooker.sh"

if [ -f /etc/arch-release ];then
  alias pr="yay --noconfirm -Runs \$(yay -Qdtq)"
  alias pu="yay --noconfirm" # Can be changed to paru or just pacman.
fi

# Related to hyprconfig.
if [ "$(uname)" != "Darwin" ];then
  alias po="poweroff"
  alias wifi="nmcli radio wifi"
  alias blue="bluetoothctl power"
  alias et="nmcli networking"
  alias lan="nmtui"
  function bt(){ nohup blueman-manager & }

  function sc(){
    grim -g "$(slurp -b 000000CC -s FFFFFF00 -c 00FF00 -w 1)" - | tee $(xdg-user-dir PICTURES)/Screenshots/screenshot_$(date +%Y-%m-%d_%H:%M:%S).png | wl-copy
  }
  alias lock="hyprlock -q -c $conf/hypr/hyprlock.conf" # Doesn't support -qc
  alias menu="rofi -config $conf/rofi.rasi -show drun &>/dev/null"
  alias wh="waybar -c $conf/waybar/config-hypr.jsonc -s $conf/waybar/style.css"
  alias wn="waybar -c $conf/waybar/config-niri.jsonc -s $conf/waybar/style.css"
  alias ns="notify-send"
  alias nss="notify-send -h int:transient:1"

  alias m="sh $scripts/menu/launch-menu.sh"
  alias my="sh $scripts/menu/launch-menu.sh -y"
  alias r="sh $scripts/reloadus.sh"
  alias br="sh $scripts/brightness.sh"

  alias journal="journalctl -xe | fzf --ghost 'These are logs of currently running services'"
  alias proc="ps aux | fzf --ghost 'These are running processes on your PC' --bind 'enter:execute(kill -9 {2})+abort'"

  alias am="wlogout -l $conf/wlogout/layout -C $conf/wlogout/wlogout.css -n"


  # Change wallpaper with theme (pywall).
  # Works only with images.
  wa() {
    wal --recursive -i $1
    local wallpaper=$(cat ~/.cache/wal/wal)
    sh $scripts/borderline.sh "$wallpaper"
    local seq=~/.cache/wal/sequences
    [[ -f "$seq" ]] && (cat "$seq" &)
    [[ -f ~/.cache/wal/colors.sh ]] && source ~/.cache/wal/colors.sh
  }

  # Change terminal color scheme. Doesn't support recursive (only file).
  co() {
    wallust run $1
    local seq=~/.cache/wallust/sequences
    [[ -f "$seq" ]] && (cat "$seq" &)
    [[ -f ~/.cache/wallust/colors.sh ]] && source ~/.cache/wallust/colors.sh
  }

  alias pa="sh $bin/path.sh"
  alias u="sh $bin/molnios.sh -u"
  alias rec="sh $scripts/record.sh"
  alias mu="sh $scripts/shazam.sh 1"
  alias shazam="sh $scripts/shazam.sh 1"

  # Mechabar - not my scripts.
  mecha=$scripts/mechabar
  alias p="sh $mecha/power-menu.sh"
  alias n="sh $mecha/network.sh "
  alias b="sh $mecha/bluetooth.sh"
  alias bu="sh $mecha/backlight.sh up 5"
  alias bd="sh $mecha/backlight.sh down 5"
  alias vu="sh $mecha/volume.sh output raise 5"
  alias vd="sh $mecha/volume.sh output lower 5"

  if exists hyprctl;then
    alias hy=hyprctl
    alias hr="hyprctl reload"
  fi
else
  alias po="shutdown -h now"
  alias blue="blueutil --power" # brew install blueutil
fi

alias y="yazi"
alias yt="yt-x -p mpv --preview"
alias fa="sh $scripts/fetch.sh -m $L_PATH/molnios-media/wallpapers/fastfetch/invincible_variants.mp4"
alias fas="sh $scripts/fetch.sh -f"
alias fast="sh $scripts/fetch.sh -m "
alias nixfetch="sh $scripts/fetch.sh -f -m $L_PATH/images/nixglass.png -w 30 -p left"
alias ca="cava -p $conf/cava.ini"
alias cat="bat -p"

alias dir="eza --icons"
alias ls="eza --icons -la"
alias l="eza --icons"
alias lt="eza --icons -TL 2"

# alias find="fd -u"
# alias grep="rg -up"

alias sakura="cbonsai -k 201,94,213,130 -lt .1"
alias sakurastatic="cbonsai -k 201,94,213,130 -t .1"
alias pokemon="pokemon-colorscripts -r"
alias e="superfile -c $conf/superfile.toml"

fbat(){
  local file
  file=$(fd -HLE .git . | fzf --ghost "Enter a file path" --preview 'if [ -d {} ]; then eza -TL 2 {}; else bat --style=numbers,changes --color=always --line-range :300 {}') && bat --style=numbers,changes --color=always "$file"
}

gtrack(){
  git ls-files | fzf --ghost "These are tracked files by git" --preview 'bat --color=always --style=numbers {}'
}

hist(){
  eval "$(history | fzf --ghost "Search your history" | sed 's/^ *[0-9]* *//')"
}

txt() {
  rg -.Sng '!.git' -g '!node_modules' "$1" | fzf +i --ghost "Type context of desired file" --ansi -d : --preview 'bat --color=always --style=numbers --highlight-line {2} {1}' --preview-window '~3,+{2}+3/2' | bat
}

we() {
  local city="${*:-}"
  city="${city// /+}"
  curl wttr.in/${city}?format=3
}

myip() {
  local script="${WHEREAMI_SCRIPT:-$scripts/whereami.sh}"

  local WHEREAMI_IP WHEREAMI_CITY WHEREAMI_REGION WHEREAMI_COUNTRY WHEREAMI_LAT WHEREAMI_LON WHEREAMI_ISP
  eval "$(sh $script --export)" || return 1

  # Build location string — omit region if empty or identical to city
  local location="$WHEREAMI_CITY"
  [[ -n "$WHEREAMI_REGION" && "$WHEREAMI_REGION" != "$WHEREAMI_CITY" ]] \
    && location+=", $WHEREAMI_REGION"
  location+=", $WHEREAMI_COUNTRY"

  echo -e "
  󰩟 IP: $WHEREAMI_IP
   Location: $location
   Coordinates: $WHEREAMI_LAT,$WHEREAMI_LON
   ISP (your provider): $WHEREAMI_ISP
"
}

alias en="printenv|fzf --ghost 'These are environment variables on your PC'"
alias a="alias|fzf --ghost 'These are existing alias in your shell'"
alias gb="git branch|fzf --ghost 'These are branches in your git repo'"

# Open config dirs.
alias v="nvim"
alias d="yazi $dir"
alias cfg="yazi $conf"
alias scr="yazi $scripts"

# Help.
man() {
  tldr "$@" 2>/dev/null || command man "$@"
}
alias lh="ln --help"

# Auto bind for cd command.
autoload -Uz add-zsh-hook
add-zsh-hook chpwd nix_hook
add-zsh-hook chpwd python_hook
add-zsh-hook chpwd nvm_hook

python_hook(){
  if [[ -d .venv ]];then
    source .venv/bin/activate
  elif [[ -d venv ]];then
    source venv/bin/activate
  elif [[ -n "$VIRTUAL_ENV" ]];then
    deactivate
  fi
}

nix_hook(){
  [[ -n $IN_NIX_SHELL || -n $NIX_DELEOP ]] && return
  [[ -f ".no-auto-nix" ]] && return
  if [[ -f "flake.nix" ]];then
    if grep -q "devShells\|devShell" flake.nix 2>/dev/null;then
      echo " Detected flake.nix - entering nix develop."
      export NIX_DEVELOP=1
      nix develop
    fi
    elif [[ -f "shell.nix" ]];then
      echo " Detected shell.nix - entering nix-shell."
      nix-shell
    fi
}

# Hook for NodeJS projects.
nvm_hook(){
  if [[ -f .nvmrc ]];then
    nvm use
  fi
}

# Aliases for files extensions.
alias -s md=codium
alias -s txt=$EDITOR
alias -s rs="cargo run"
alias -s py=python
alias -s pdf=masterpdfeditor5
alias -s sh=sh
alias -s yaml="bat -l yaml"
alias -s json=jq

alias -s zip=$COMPRESSOR
alias -s 7z=$COMPRESSOR
alias -s rar=$COMPRESSOR
alias -s tar=$COMPRESSOR
alias -s gz=$COMPRESSOR

alias -s png=$PHOTO
alias -s jpg=$PHOTO
alias -s svg=$PHOTO

alias -s mp3=$MEDIA
alias -s opus=$MEDIA
alias -s mkv=$MEDIA
alias -s mp4=$MEDIA
alias -s mov=$MEDIA

# 6. ZSH highlight colors — Gruvbox theme. (requires 24-bit terminal)
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#fb4934,bold'        # bright red   — not found
ZSH_HIGHLIGHT_STYLES[command]='fg=#b8bb26'                   # bright green — known command
ZSH_HIGHLIGHT_STYLES[path]='fg=#fabd2f'                      # bright yellow — file/dir
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#8ec07c'                   # bright aqua  — zsh built-in
ZSH_HIGHLIGHT_STYLES[alias]='fg=#fe8019'                     # bright orange — alias
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#83a598'    # bright blue  — 'string'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#d3869b'    # bright purple — "string"
ZSH_HIGHLIGHT_STYLES[comment]='fg=#928374'                   # gray   — # comments
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#fabd2f,bold'             # yellow — wildcards like *
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#fe8019'               # orange — >, >>
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#fb4934'          # red    — ;, |, &&
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#b8bb26'                      # green  — first word of command

# 7. Theme config.
source $conf/zsh/.p10k.zsh

# 8. ZSH settings.
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons $realpath'

eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
export _PR_AI_ADDITIONAL_PROMPT="User is on Arch Linux or nixOS with Fish shell. Answer him the questions for both systems."
eval "$(pay-respects zsh)"

# 9. Keybinds.
# Shift + arrows. [moving]
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# ZSH autosuggestion shift keybind.
bindkey '^[[Z' autosuggest-accept
bindkey '^\' autosuggest-toggle

# History search with Up/Down.
# 1. Load the internal functions from Zsh
autoload -U up-line-or-beginning-search down-line-or-beginning-search
# 2. Register them as ZLE widgets
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
# 3. Bind them to physical keys (Handles standard, Kitty, and WezTerm escape codes)
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

# Edit command line.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^Xe' edit-command-line

# Undo/redo.
bindkey '^Xu' undo
bindkey '^Y' redo

# Clear screen but keep current command buffer (position).
function clear-screen-and-scrollback() {
  echoti civis >"$TTY"
  printf '%b' '\e[H\e[2J\e[3J' >"$TTY"
  echoti cnorm >"$TTY"
  zle redisplay
}
zle -N clear-screen-and-scrollback
bindkey '^Xl' clear-screen-and-scrollback

# Copy text.
if [[ "$(uname)" = "Darwin" ]]; then
  clipboard_cmd=pbcopy
else
  clipboard_cmd=wl-copy
fi

copy-buffer-to-clipboard() {
  echo -n "$BUFFER" | $clipboard_cmd
  zle -M "Copied to clipboard"
}

zle -N copy-buffer-to-clipboard
bindkey '^Xc' copy-buffer-to-clipboard

# Dynamic hotkeys. (custom cursor placement).
git-commit-msg() {
  LBUFFER+='git commit -m "'
  RBUFFER='"'
}
zle -N git-commit-msg
bindkey '^Xgc' git-commit-msg
bindkey -s '^Xgp' 'git push origin '
bindkey -s '^Xgs' 'git status\n'
bindkey -s '^Xgl' 'git log --oneline -n 10\n'


wal-folder() {
  LBUFFER+='wal --recursive -i "'
  RBUFFER='"'
}
zle -N wal-folder
bindkey '^Xw' wal-folder