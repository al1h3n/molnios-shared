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
share=/usr/share
sharel=~/.local/share
bin=/usr/local/bin

dir="$sharel/molnios"
scripts=$dir/scripts
conf=$dir/config

# 2. Functions and custom commands.

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
alias u="sh $bin/molniux.sh -u"

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

# Keybinds.

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

# Plugins.
z=$share/zsh # ZSH location.
zl=$sharel/zsh

if [ -f /etc/os-release ] && grep -q "NixOS" /etc/os-release; then
  # NixOS - plugins sourced by home-manager, skip
  source $share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme 2>/dev/null || true
else
  # Arch
  source $z/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh # Auto suggestions.
  source $z/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh # Color syntax.
  source $z/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
  source $share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme # zsh-theme-powerlevel10k-git.
  source $zl/plugins/zsh-shift-select/zsh-shift-select.plugin.zsh # git clone https://github.com/jirutka/zsh-shift-select ~/.local/share/zsh/plugins/zsh-shift-select
fi
source $conf/.p10k.zsh # Write 'p10k configure' to configure.

# Plugin configurations.

# zsh highlight colors.
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold' # Not found command.
ZSH_HIGHLIGHT_STYLES[command]='fg=green' # Known command.
ZSH_HIGHLIGHT_STYLES[path]='fg=yellow' # Directory or file.
ZSH_HIGHLIGHT_STYLES[builtin]='fg=cyan' # A zsh built-in command.
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan' # Alias (dedicated command).
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=blue'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=blue,bold'