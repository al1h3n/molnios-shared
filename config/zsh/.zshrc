# ==========================================================
# zshconfig al1h3n edition.
# Used powerlevel10k theme.
# ==========================================================

# Temp files will be saved in ~/.cache/zsh, ~/.zsh_history

# Must be called .zshrc
# Insert in ~/.zshenv
# export ZDOTDIR=/al1h3n/config

# .zshenv is used for non interactive actions, .zshrc only when user opens terminal interactively.

# Set default shell.
# chsh -s $(which zsh)

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
sharel=~/.local/share
bin=/usr/local/bin

dir="$sharel/molnios"
scripts=$dir/scripts
conf=$dir/config

# ZSH history.
HISTSIZE=5000
SAVEHIST=$HISTSIZE
HISTFILE=~/.zsh_history
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space # Use spacebar to prevent unimportant commands to be written.
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# 1. Plugin manager.
if [ -n "$ZINIT_HOME" ] && [ -f "$ZINIT_HOME/zinit.zsh" ];then
  # NixOS / MaconlyOS - ZINIT_HOME set by home-manager in zsh.nix.
  source $ZINIT_HOME/zinit.zsh
else
  # Arch - auto-install zinit if missing.
  ZINIT_HOME=$sharel/zinit/zinit.git
  if [ ! -d $ZINIT_HOME ];then
    mkdir -p $(dirname $ZINIT_HOME)
    git clone https://github.com/zdharma-continuum/zinit.git $ZINIT_HOME
  fi
  source $ZINIT_HOME/zinit.zsh
fi

# 2. Plugins via zinit.

# Theme - load first, instantly.
zinit ice depth=1
zinit light romkatv/powerlevel10k

# Core plugins.
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light jirutka/zsh-shift-select
zinit light Aloxaf/fzf-tab # zinit light marlonrichert/zsh-autocomplete

# Autocomplete - needs to load after compinit.
# zinit ice wait lucid

# Auto-completion from OhMyZsh. Like gst - aliased to git status.
zinit snippet OMZP::git # Imports custom commands.
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# 4. Completions init.
autoload -Uz compinit
mkdir -p ~/.cache/zsh/zcompdump
compinit -d ~/.cache/zsh/zcompdump
zinit cdreplay -q

# 5. Functions and custom commands.

# Clear everything or just move above.
alias c='printf "\e[H\e[3J"'
alias cl='printf "\e[H\e[22J"'

# Helpful
alias h="apropos"
alias help="apropos"
alias s="doas"
alias duf="duf --only local"
alias sud="su -c"
alias g="git --filter=blob:none --depth=1"
alias k="killall"
alias pk="pkill"
alias q="zsh"
alias re="reboot"
alias sl="sleep"
alias ln="ln -sfn"
alias ki="kitty -c $conf/kitty.conf"
alias ze="zellij -c $conf/zellij/config.kdl"
alias kitty="kitty -c $conf/kitty.conf"
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

if [ -f /etc/arch-release ];then
  zinit snippet OMZP::archlinux
  alias pr="yay --noconfirm -Runs $(yay -Qdtq)"
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
  alias lock="hyprlock -q -c $conf/hyprlock.conf" # Doesn't support -qc
  alias menu="rofi -config $conf/rofi.rasi -show drun &>/dev/null"
  alias wh="waybar -c $conf/waybar/config-hypr.jsonc -s $conf/waybar/style.css"
  alias wn="waybar -c $conf/waybar/config-niri.jsonc -s $conf/waybar/style.css"
  alias ns="notify-send"

  alias m="sh $scripts/menu/launch-menu.sh"
  alias my="sh $scripts/menu/launch-menu.sh -y"
  alias r="sh $scripts/reloadus.sh"

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
else
  alias po="shutdown -h now"
  alias blue="blueutil --power" # brew install blueutil
fi

alias y="yazi"
alias yt="yt-x -p mpv --preview"
alias fa="sh $scripts/fetch.sh -m $L_PATH/molnios-media/wallpapers/fastfetch/invincible_variants.mp4"
alias fas="sh $scripts/fetch.sh -f"
alias fast="sh $scripts/fetch.sh -m "
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
  rg -.Sng '!.git' -g '!node_modules' "$1" | fzf --ghost "Type context of desired file" --ansi -d : --preview 'bat --color=always --style=numbers --highlight-line {2} {1}' --preview-window '~3,+{2}+3/2' | bat
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
alias d="$y $dir"
alias cfg="$y $conf"
alias scr="$y $scripts"

# Help.
man() {
  tldr "$@" 2>/dev/null || command man "$@"
}
alias lh="ln --help"

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
export _PR_AI_ADDITIONAL_PROMPT="User is on Arch Linux or nixOS with Zsh and Hyprland. Answer him the questions for both systems."
alias f="$(pay-respects zsh)"

# 9. Keybinds.

# Moving in between words.

# Shift + arrows. [moving]
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# Ctrl + shift + arrows. [selection]
bindkey "^[[1;6D" backward-select-word
bindkey "^[[1;6C" forward-select-word
# bindkey "^[[1;6D" select-beginning-of-word
# bindkey "^[[1;6C" select-end-of-word

# ZSH autosuggestion shift keybind.
bindkey '^[[Z' autosuggest-accept

# History search with Ctrl+Up/Down.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[1;5A" history-search-backward
bindkey "^[[1;5B" history-search-forward