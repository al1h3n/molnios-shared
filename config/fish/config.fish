# ==========================================================
# fishconfig al1h3n edition.
# Used Tide theme.
# ==========================================================

# Temp files will be saved in ~/.local/share/fish/

# Set default shell.
# chsh -s $(which fish)

# Remove greeting.
set -g fish_greeting

# ==========================================================
# Pokemons.
# ==========================================================
pokemon-colorscripts -r

# ==========================================================
# Terminal colors.
# ==========================================================
set _tc_state (test -n "$XDG_CACHE_HOME"; and echo "$XDG_CACHE_HOME"; or echo "$HOME/.cache")/molnios/colors

if test -f $_tc_state
    set _tc_seq (cat $_tc_state 2>/dev/null)
    if test -f "$_tc_seq"
        cat "$_tc_seq" 2>/dev/null &

        # Source the matching colors.fish for shell variable access.
        set _tc_colors (string replace '/sequences' '/colors.fish' $_tc_seq)
        if test -f "$_tc_colors"
            source "$_tc_colors"
        end
        set --erase _tc_colors
    end
    set --erase _tc_seq
end
set --erase _tc_state

# ==========================================================
# Tide theme setup.
# Run once after install to configure Tide:
tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time=No --rainbow_prompt_separators=Angled --powerline_prompt_heads=Sharp --powerline_prompt_tails=Slanted --powerline_prompt_style='Two lines, character' --prompt_connection=Disconnected --powerline_right_prompt_frame=No --prompt_spacing=Compact --icons='Many icons' --transient=Yes
# One line adds "D symbol".
# --powerline_prompt_tails=Round or Slanted
# ==========================================================

# ==========================================================
# 0. Variables.
# ==========================================================
set -gx EDITOR nvim
set -g sharel ~/.local/share
set -g bin /usr/local/bin

set -g dir "$sharel/molnios"
set -g scripts "$dir/scripts"
set -g conf "$dir/config"

# Completions init (built into fish, auto-loaded).
# Fish history (built-in, no manual config needed).
# Fish automatically deduplicates and persists history.

# ==========================================================
# 2. Aliases and functions.
# ==========================================================

# Clear everything or just move above.
alias c='printf "\e[H\e[3J"'
alias cl='printf "\e[H\e[22J"'

# Helpful.
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
alias ze="zellij -c $conf/zellij/config.kdl"
alias kitty="kitty -c $conf/kitty.conf"

function rr --description "rm-improved: safely remove files with confirmation"
    if test (count $argv) -eq 0
        echo "Usage: rr <files>"
        return 1
    end

    read --prompt-str "Do you want to run rm -rf $argv [y/n]? " reply

    if string match -qr '^[Yy]$' -- $reply
        sudo rm -rf $argv
    else
        echo "\nCancelled."
    end
end

# VPN (Warp).
alias vq="warp-cli disconnect"
alias vw="warp-cli status"
alias ve="warp-cli connect"
alias vr="warp-cli registration delete"
alias vt="warp-cli registration new"

alias sw="sh $bin/sweeper.sh"

# ==========================================================
# 3. OS-specific config.
# ==========================================================

if test -f /etc/arch-release
    alias pr="yay --noconfirm -Runs (yay -Qdtq)"
    alias pu="yay --noconfirm"
end

if test (uname) != Darwin
    alias po="poweroff"
    alias wifi="nmcli radio wifi"
    alias blue="bluetoothctl power"
    alias et="nmcli networking"
    alias lan="nmtui"

    function bt --description "Open bluetooth manager"
        nohup blueman-manager &
    end

    function sc --description "Screenshot selected area to clipboard and Pictures"
        grim -g (slurp -b 000000CC -s FFFFFF00 -c 00FF00 -w 1) - \
            | tee (xdg-user-dir PICTURES)/Screenshots/screenshot_(date +%Y-%m-%d_%H:%M:%S).png \
            | wl-copy
    end

    alias lock="hyprlock -q -c $conf/hyprlock.conf"
    alias menu="rofi -config $conf/rofi.rasi -show drun &>/dev/null"
    alias wh="waybar -c $conf/waybar/config-hypr.jsonc -s $conf/waybar/style.css"
    alias wn="waybar -c $conf/waybar/config-niri.jsonc -s $conf/waybar/style.css"
    alias ns="notify-send"

    alias m="sh $scripts/menu/launch-menu.sh"
    alias my="sh $scripts/menu/launch-menu.sh -y"
    alias r="sh $scripts/reloadus.sh"

    alias journal="journalctl -xe | fzf --placeholder 'These are logs of currently running services'"
    alias proc="ps aux | fzf --placeholder 'These are running processes on your PC' --bind 'enter:execute(kill -9 {2})+abort'"

    alias am="wlogout -l $conf/wlogout/layout -C $conf/wlogout/wlogout.css -n"

    # Change wallpaper with theme (pywal).
    function wa --description "Set wallpaper and change terminal colors via pywal"
        wal --recursive -i $argv[1]
        set wallpaper (cat ~/.cache/wal/wal)
        sh $scripts/borderline.sh "$wallpaper"
        set seq ~/.cache/wal/sequences
        if test -f "$seq"
            cat "$seq" &
        end
        if test -f ~/.cache/wal/colors.fish
            source ~/.cache/wal/colors.fish
        end
    end

    # Change terminal color scheme.
    function co --description "Change terminal colors via wallust"
        wallust run $argv[1]
        set seq ~/.cache/wallust/sequences
        if test -f "$seq"
            cat "$seq" &
        end
        if test -f ~/.cache/wallust/colors.fish
            source ~/.cache/wallust/colors.fish
        end
    end

    alias pa="sh $bin/path.sh"
    alias u="sh $bin/molnios.sh -u"
    alias rec="sh $scripts/record.sh"
    alias mu="sh $scripts/shazam.sh 1"
    alias shazam="sh $scripts/shazam.sh 1"

    # Mechabar.
    set mecha "$scripts/mechabar"
    alias p="sh $mecha/power-menu.sh"
    alias n="sh $mecha/network.sh"
    alias b="sh $mecha/bluetooth.sh"
    alias bu="sh $mecha/backlight.sh up 5"
    alias bd="sh $mecha/backlight.sh down 5"
    alias vu="sh $mecha/volume.sh output raise 5"
    alias vd="sh $mecha/volume.sh output lower 5"
else
    alias po="shutdown -h now"
    alias blue="blueutil --power"
end

# ==========================================================
# 4. Tools and utilities.
# ==========================================================

alias y="yazi" # --clear-cache
alias yt="yt-x -p mpv --preview"
alias fa="sh $scripts/fetch.sh -m $L_PATH/molnios-media/wallpapers/fastfetch/invincible_variants.mp4"
alias fas="sh $scripts/fetch.sh -f"
alias fast="sh $scripts/fetch.sh -m"
alias ca="cava -p $conf/cava.ini"
alias cat="bat -p"

alias dir="eza --icons"
alias ls="eza --icons -la"
alias l="eza --icons"
alias lt="eza --icons -TL 2"

alias sakura="cbonsai -k 201,94,213,130 -lt .1"
alias sakurastatic="cbonsai -k 201,94,213,130 -t .1"
alias pokemon="pokemon-colorscripts -r"
alias e="superfile -c $conf/superfile.toml"

# ==========================================================
# 5. fzf functions.
# ==========================================================

function fbat --description "Find file with fzf and display it with bat"
    set file (fd -HLE .git . \
        | fzf --placeholder "Enter a file path" \
              --preview 'if [ -d {} ]; then eza -TL 2 {}; else bat --style=numbers,changes --color=always --line-range :300 {}; fi')
    and bat --style=numbers,changes --color=always "$file"
end

function gtrack --description "Browse git-tracked files with fzf"
    git ls-files \
        | fzf --placeholder "These are tracked files by git" \
              --preview 'bat --color=always --style=numbers {}'
end

function hist --description "Search and execute command from history"
    set cmd (history | fzf --placeholder "Search your history")
    and commandline -- $cmd
    and commandline -f execute
end

function txt --description "Find text in files using ripgrep and fzf"
    rg -.Sng '!.git' -g '!node_modules' "$argv[1]" \
        | fzf --placeholder "Type context of desired file" \
              --ansi -d : \
              --preview 'bat --color=always --style=numbers --highlight-line {2} {1}' \
              --preview-window '~3,+{2}+3/2' \
        | bat
end

function we --description "Show weather for a city (uses wttr.in)"
    set city (string join '+' $argv)
    curl wttr.in/$city?format=3
end

function myip --description "Show public IP, location and ISP"
    set script (test -n "$WHEREAMI_SCRIPT"; and echo "$WHEREAMI_SCRIPT"; or echo "$scripts/whereami.sh")

    # Export variables from the script.
    for line in (sh $script --export | string split \n)
        set kv (string split '=' $line)
        set -gx $kv[1] $kv[2]
    end
    or return 1

    set location $WHEREAMI_CITY
    if test -n "$WHEREAMI_REGION" -a "$WHEREAMI_REGION" != "$WHEREAMI_CITY"
        set location "$location, $WHEREAMI_REGION"
    end
    set location "$location, $WHEREAMI_COUNTRY"

    echo "
  󰩟 IP: $WHEREAMI_IP
   Location: $location
   Coordinates: $WHEREAMI_LAT,$WHEREAMI_LON
   ISP (your provider): $WHEREAMI_ISP
"
end

alias en="printenv | fzf --placeholder 'These are environment variables on your PC'"
alias a="alias | fzf --placeholder 'These are existing aliases in your shell'"
alias gb="git branch | fzf --placeholder 'These are branches in your git repo'"

# ==========================================================
# 6. Editor and navigation.
# ==========================================================

alias v="nvim"
alias d="yazi $dir"
alias cfg="yazi $conf"
alias scr="yazi $scripts"

function man --description "Use tldr first, fallback to man"
    tldr $argv 2>/dev/null
    or command man $argv
end

alias lh="ln --help"

# ==========================================================
# 7. Shell integrations.
# ==========================================================

# fzf key bindings and completions (via fzf-fish plugin).
fzf --fish | source

# Zoxide (smart cd).
zoxide init --cmd cd fish | source

# Pay Respects (fix last command).
pay-respects fish | source

# ==========================================================
# 8. Environment variables.
# ==========================================================
set -gx _PR_AI_ADDITIONAL_PROMPT "User is on Arch Linux or nixOS with Fish and Hyprland. Answer him the questions for both systems."

# ==========================================================
# 9. Keybinds.
# ==========================================================