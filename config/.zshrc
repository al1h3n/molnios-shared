# ==========================================================
# zshconfig al1h3n edition - v1
# Used powerlevel10k theme.
# Changed: first release.
# ==========================================================

# 0. Pre-installing.

# Must be called .zshrc
# Insert in ~/.zshenv
# export ZDOTDIR=/al1h3n/config

# Set default shell.
# chsh -s $(which zsh)

# 1. Pre-definitions.
sharel=~/.local/share
bin=/usr/local/bin

dir="$sharel/molnios"
scripts=$dir/scripts
conf=$dir/config

# 2. Plugin manager.
# Zinit setup - works on Arch, macOS, nixOS.
if [ -f /etc/os-release ] && grep -q "NixOS" /etc/os-release; then
  # NixOS - zinit installed via nixpkgs.
  source @ZINIT_PATH@ # replaced by nix at build time
else
  # Arch + macOS - auto-install zinit if missing.
  ZINIT_HOME=$sharel/zinit/zinit.git
  if [ ! -d $ZINIT_HOME ]; then
    mkdir -p $(dirname $ZINIT_HOME)
    git clone https://github.com/zdharma-continuum/zinit.git $ZINIT_HOME
  fi
  source $ZINIT_HOME/zinit.zsh
fi

# 3. Plugins via zinit.

# Theme - load first, instantly.
zinit ice depth=1
zinit light romkatv/powerlevel10k

# Core plugins.
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light jirutka/zsh-shift-select

# Autocomplete - needs to load after compinit.
zinit ice wait lucid
zinit light marlonrichert/zsh-autocomplete

# 4. Completions init.
autoload -Uz compinit
compinit

# 5. Functions and custom commands.

function sc(){
    grim -g "$(slurp -b 000000CC -s FFFFFF00 -c 00FF00 -w 1)" - | tee $(xdg-user-dir PICTURES)/Screenshots/screenshot_$(date +%Y-%m-%d_%H:%M:%S).png | wl-copy
}

# Clear everything or just move above.
alias c='printf "\e[H\e[3J"'
alias cl='printf "\e[H\e[22J"'

# Helpful
alias text="nvim -y"
alias s="sudo"
alias k="killall"
alias q="zsh"
alias po="poweroff"
alias re="reboot"
alias ns="notify-send"
alias sl="sleep"
alias ln="ln -sfn"
rr(){ # rm-improved
  # 1. Check if files were actually passed to the command
  if [ $# -eq 0 ]; then
    echo "Usage: rr <files>"
    return 1
  fi

  # 2. Prompt the user.
  # "$*" shows the list of files you are about to delete
  read "Do you want to run rm -rf $* [y/n]? "

  # 3. Check if the answer is 'y' or 'Y'
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    sudo rm -rf $@
  else
    echo "\nCancelled."
  fi
}

# github.com/Alihan1ai9595/sweeper
# Custom scripts for paths in Molniux.
alias sw="sh $bin/sweeper.sh"
alias p="sh $bin/path.sh"
alias u="sh $bin/molnios.sh -u"

alias rec="sh $scripts/record.sh"
alias r="sh $scripts/reloadus.sh" # Reload hyprland.

# Related to hyprconfig.
alias lock="hyprlock -q -c $conf/hyprlock"
alias menu="rofi -config $conf/rofi -show drun &>/dev/null"
alias y="yazi"
alias yt="yt-x -p mpv --preview"
alias f="sh $scripts/fastfetch.sh"
alias wb="waybar -c $conf/waybar/waybar -s $conf/waybar/waybarstyle"

alias dir="eza --icons"
alias ls="eza --icons"
alias l="eza --icons"
alias lt="eza --icons -T -L 2"

# Connection.
alias lan=nmtui
function bt(){
    nohup blueman-manager &
}

# Open config dirs.
alias d="nvim $dir"
alias conf="nvim $conf"
alias scr="nvim $scripts"

# Help.
alias lh="ln --help"

# Mechabar - not my scripts.
mecha=$scripts/mechabar/scripts
alias p="sh $mecha/power-menu.sh"
alias uu="sh $mecha/system-update.sh"
alias n="sh $mecha/network.sh "
alias b="sh $mecha/bluetooth.sh"

# 6. Keybinds.

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

# 7. ZSH highlight colors.
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold' # Not found command.
ZSH_HIGHLIGHT_STYLES[command]='fg=green' # Known command.
ZSH_HIGHLIGHT_STYLES[path]='fg=yellow' # Directory or file.
ZSH_HIGHLIGHT_STYLES[builtin]='fg=cyan' # A zsh built-in command.
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan' # Alias (dedicated command).
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=blue'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=blue,bold'

# 8. Theme config.
source $conf/.p10k.zsh