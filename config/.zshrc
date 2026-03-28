# ==========================================================
# zshconfig al1h3n edition.
# Used powerlevel10k theme.
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

# ZSH history.
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space # Use spacebar to prevent unimportant commands to be written.
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# 2. Plugin manager.
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

# 3. Plugins via zinit.

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
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# 4. Completions init.
autoload -Uz compinit
compinit
zinit cdreplay -q

# 5. Functions and custom commands.

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
alias sl="sleep"
alias ln="ln -sfn"
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

# github.com/Alihan1ai9595/sweeper
# Custom scripts for paths in Molniux.
alias sw="sh $bin/sweeper.sh"
alias pa="sh $bin/path.sh"
alias u="sh $bin/molnios.sh -u"

alias rec="sh $scripts/record.sh"


# Related to hyprconfig.
if [ "$(uname)" != "Darwin" ];then
  zinit snippet OMZP::archlinux
  function sc(){
    grim -g "$(slurp -b 000000CC -s FFFFFF00 -c 00FF00 -w 1)" - | tee $(xdg-user-dir PICTURES)/Screenshots/screenshot_$(date +%Y-%m-%d_%H:%M:%S).png | wl-copy
  }
  alias lock="hyprlock -q -c $conf/hyprlock"
  alias menu="rofi -config $conf/rofi -show drun &>/dev/null"
  alias wb="waybar"
  alias lan="nmtui"
  alias ns="notify-send"

  alias r="sh $scripts/reloadus.sh" # Reload hyprland.
  function bt(){ nohup blueman-manager & }
fi


alias y="yazi"
alias yt="yt-x -p mpv --preview"
alias fa="sh $scripts/fastfetch.sh"
alias cat="bat"

alias dir="eza --icons"
alias ls="eza --icons -la"
alias l="eza --icons"
alias lt="eza --icons -T -L 2"

# Open config dirs.
alias d="nvim $dir"
alias cfg="nvim $conf"
alias scr="nvim $scripts"

# Help.
man() {
  tldr "$@" 2>/dev/null || command man "$@"
}
alias lh="ln --help"

# Mechabar - not my scripts.
mecha=$scripts/mechabar/scripts
alias p="sh $mecha/power-menu.sh"
alias uu="sh $mecha/system-update.sh"
alias n="sh $mecha/network.sh "
alias b="sh $mecha/bluetooth.sh"

# 6. ZSH highlight colors.
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold' # Not found command.
ZSH_HIGHLIGHT_STYLES[command]='fg=green' # Known command.
ZSH_HIGHLIGHT_STYLES[path]='fg=yellow' # Directory or file.
ZSH_HIGHLIGHT_STYLES[builtin]='fg=cyan' # A zsh built-in command.
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan' # Alias (dedicated command)
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=blue'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=blue,bold'

# 7. Theme config.
source $conf/.p10k.zsh

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