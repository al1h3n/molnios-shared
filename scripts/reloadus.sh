# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - paypal.me/al1h3n
# Reloadus - based on hypreload.sh project.
# ==============================================================================

#!/bin/bash
echo -e "\033]0;HR v2 - al1h3n\007"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"
CONF=$L_PATH/config

echo -e "\e[38;2;51;204;254mReload\e[38;2;0;255;153mus \e[38;2;11;206;217mby\033[0m \033[38;5;171mal1h3n${RESET}"

exists(){
	command -v $@&>/dev/null
}

kp(){ # Kill process
	if pgrep&>/dev/null $1; then
		pkill $1
	fi
}

run(){
	$@&>/dev/null &
}

# 1.1. Dependencies.
# if ! exists zenity;then
# 	echo -e "${RED}You have to install ${YELLOW}zenity${RED} package.${RESET}"
# 	read;exit 0
# fi

# 1.2. Wallpaper engines.
if exists waypaper;then
	waypaper --restore&>/dev/null
fi
if exists swww;then
	swww clear-cache
fi
if exists awww;then
	awww clear-cache
fi

# 1.3. Bar.
if exists waybar;then
	kp waybar
	WAY=$CONF/waybar
	if [ -n $HYPRLAND_INSTANCE_SIGNATURE ];then
		run waybar -c $WAY/config-hypr.jsonc -s $WAY/style.css
	elif [ $XDG_CURRENT_DESKTOP = "niri" ];then
		run waybar -c $WAY/config-niri.jsonc -s $WAY/style.css
	fi
fi

# 1.4. Notifications.
if exists swaync;then
	kp swaync
	run swaync -c $CONF/swaync/swaync.json -s $CONF/swaync/swaync-style.css
elif exists dunst;then
	kp dunst
	run dunst -conf $CONF/dunst.ini
fi

# 1.5 Hyprland/Niri.
if [ -n $HYPRLAND_INSTANCE_SIGNATURE ];then
	hyprctl reload&>/dev/null
	if exists snappy-switcher;then
		run snappy-switcher --daemon -c $CONF/snappy.ini
	fi
elif [ $XDG_CURRENT_DESKTOP = "niri" ];then
	niri msg action load-config-file&>/dev/null
fi


echo -e "\n\033[38;5;46mConfigurations were successfully reloaded.${RESET}"

# Legacy.
# mpvpaper was removed due to waypaper usage.
# if exists mpvpaper;then
# 	kp mpvpaper
# 	video=$(zenity --file-selection --title="Select mpvpaper video"&>/dev/null)
# 	run mpvpaper -s -o "--loop --mute --no-osd-bar --no-input-default-bindings" ALL $video
# fi
