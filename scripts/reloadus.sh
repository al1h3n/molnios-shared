#!/usr/bin/env bash
# Reloadus - based on hypreload.sh project.
# ==============================================================================

GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

echo -e "\e[38;2;51;204;254mReload\e[38;2;0;255;153mus \e[38;2;11;206;217mby\033[0m \033[38;5;171mal1h3n${RESET}"

pids(){ # PIDs of a running program.
	# pgrep -x matches /proc/PID/comm, which is capped at 15 characters and on
	# NixOS holds the wrapper name ".<program>-wrapped" (noctalia -> ".noctalia-wrapp").
	# So resolve /proc/PID/exe instead and strip the wrapper decoration.
	local dir pid exe base found=""
	for dir in /proc/[0-9]*; do
		pid="${dir#/proc/}"
		[ "$pid" = "$$" ] && continue
		exe="$(readlink "$dir/exe" 2>/dev/null)" || continue
		base="${exe##*/}"
		base="${base% (deleted)}"
		base="${base#.}"
		base="${base%-wrapped}"
		[ "$base" = "$1" ] && found="$found $pid"
	done
	[ -n "$found" ] || return 1
	printf '%s\n' $found
}

exists(){ # True only if a process of the given program is running.
	pids "$1" >/dev/null
}

installed(){ # True if the command exists (for one-shot tools with no daemon).
	command -v -- "$1" &>/dev/null
}

kp(){ # Kill a process and wait for it to actually die, so the restart cannot race it.
	local list pid i
	list="$(pids "$1")" || return 1
	kill $list 2>/dev/null
	for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
		pids "$1" >/dev/null || return 0
		sleep 0.1
	done
	kill -9 $list 2>/dev/null
	sleep 0.2
}

run(){ # Start a program detached, so it survives this script and its terminal.
	setsid -f "$@" &>/dev/null || "$@" &>/dev/null &
}

reloaded(){ echo -e "  ${GREEN}$1${RESET} reloaded."; }
started(){ echo -e "  ${GREEN}$1${RESET} was not running, started."; }
skipped(){ echo -e "  ${YELLOW}$1${RESET} is not installed, skipped."; }

session_env(){ # Session variables of the graphical session owned by uid $1, first value wins.
	local uid="$1" dir pid line key list want
	want='^(WAYLAND_DISPLAY|XDG_RUNTIME_DIR|XDG_CURRENT_DESKTOP|DBUS_SESSION_BUS_ADDRESS|DISPLAY|XAUTHORITY|HYPRLAND_INSTANCE_SIGNATURE|L_PATH|HOME|PATH)='
	declare -A seen
	# The compositor carries the login PATH, HOME and L_PATH but never WAYLAND_DISPLAY,
	# which only its children get. Read the compositor first, then everything else.
	list="$(pids niri) $(pids Hyprland) $(pids sway) $(pids river)"
	for dir in /proc/[0-9]*; do list="$list ${dir#/proc/}"; done
	for pid in $list; do
		[ "$(stat -c %u "/proc/$pid" 2>/dev/null)" = "$uid" ] || continue
		while IFS= read -r line; do
			key="${line%%=*}"
			[ -n "${seen[$key]}" ] && continue
			seen[$key]=1
			printf '%s\n' "$line"
		done < <({ tr '\0' '\n' < "/proc/$pid/environ" | grep -E "$want"; } 2>/dev/null)
	done
	[ -n "${seen[WAYLAND_DISPLAY]}" ]
}

# Never act as root. Root has no Wayland socket and no user PATH, so every IPC
# reload fails, the restart fallback kills the user daemons and cannot start them
# again. Drop back into the real session instead.
if [ "$(id -u)" -eq 0 ];then
	TARGET="${SUDO_USER:-${DOAS_USER:-}}"
	if [ -n "$TARGET" ] && [ "$TARGET" != root ];then
		mapfile -t SESSION < <(session_env "$(id -u "$TARGET")")
	fi
	if [ "${#SESSION[@]}" -gt 0 ];then
		echo -e "${YELLOW}Running as root, switching back to ${TARGET}.${RESET}"
		exec sudo -u "$TARGET" env "${SESSION[@]}" bash -- "$0" "$@"
	fi
	echo -e "${RED}Refusing to run as root: no graphical session found.${RESET}"
	echo -e "Run this script as your desktop user instead."
	exit 1
fi

: "${L_PATH:=$HOME/.local/share/molnios}"
CONF="$L_PATH/config"

# 1.1. Wallpaper engines.
# Clear the cache before repainting, otherwise the stale cache is what gets drawn.
if exists swww-daemon;then
	swww clear-cache &>/dev/null
	reloaded swww-daemon
fi
if exists awww-daemon;then
	awww clear-cache &>/dev/null
	reloaded awww-daemon
fi
if installed waypaper;then
	waypaper --restore &>/dev/null
	reloaded waypaper
fi

# 1.2. Bar.
# if exists waybar;then
# 	kp waybar
# 	WAY=$CONF/waybar
# 	if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ];then
# 		run waybar -c $WAY/config-hypr.jsonc -s $WAY/style.css
# 	elif [ "$XDG_CURRENT_DESKTOP" = "niri" ];then
# 		run waybar -c $WAY/config-niri.jsonc -s $WAY/style.css
# 	fi
# fi
if exists noctalia;then # Noctalia v5.
	# Native IPC reload keeps the bar, dock and widgets alive. Restart only if it fails.
	if noctalia msg config-reload &>/dev/null;then
		noctalia msg dock-reload &>/dev/null
		reloaded noctalia
	else
		kp noctalia
		run noctalia
		started noctalia
	fi
elif installed noctalia;then
	run noctalia
	started noctalia
else
	skipped noctalia
fi

# 1.3. Notifications.
if exists swaync;then
	if swaync-client --reload-config --reload-css &>/dev/null;then
		reloaded swaync
	else
		kp swaync
		run swaync -c "$CONF/swaync/swaync.json" -s "$CONF/swaync/swaync-style.css"
		started swaync
	fi
elif exists dunst;then
	if dunstctl reload "$CONF/dunst.ini" &>/dev/null;then
		reloaded dunst
	else
		kp dunst
		run dunst -conf "$CONF/dunst.ini"
		started dunst
	fi
elif installed swaync;then
	run swaync -c "$CONF/swaync/swaync.json" -s "$CONF/swaync/swaync-style.css"
	started swaync
elif installed dunst;then
	run dunst -conf "$CONF/dunst.ini"
	started dunst
else
	skipped "notification daemon"
fi

# 1.4 Hyprland/Niri.
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ];then
	hyprctl reload &>/dev/null
	reloaded hyprland
	if installed snappy-switcher;then
		kp snappy-switcher
		run snappy-switcher --daemon -c "$CONF/snappy.ini"
		reloaded snappy-switcher
	fi
elif [ "$XDG_CURRENT_DESKTOP" = "niri" ];then
	niri msg action load-config-file &>/dev/null
	reloaded niri
fi

echo -e "\n\033[38;5;46mConfigurations were successfully reloaded.${RESET}"

# Legacy.
# mpvpaper was removed due to waypaper usage.
# if exists mpvpaper;then
# 	kp mpvpaper
# 	video=$(zenity --file-selection --title="Select mpvpaper video"&>/dev/null)
# 	run mpvpaper -s -o "--loop --mute --no-osd-bar --no-input-default-bindings" ALL $video
# fi