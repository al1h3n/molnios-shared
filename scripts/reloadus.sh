# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - paypal.me/al1h3n
# Reloadus v1 - based on hypreload.sh project.
# ==============================================================================

#!/bin/bash
echo -e "\033]0;HR v1 - al1h3n\007"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

echo -e "\e[38;2;51;204;254mReload\e[38;2;0;255;153mus \e[38;2;11;206;217mby\033[0m \033[38;5;171mal1h3n${RESET}"

exists(){
	command -v $1&>/dev/null
}

kp(){ # Kill process
	if pgrep&>/dev/null $1; then
		pkill $1
	fi
}

run(){
	nohup $1&>/dev/null &
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

# 1.3. Utilities.
if exists waybar;then
	kp waybar
	run waybar
fi

# 1.4. Hyprland itself.
if exists hyprland;then
	hyprctl reload&>/dev/null
else
	echo -e "${RED}You don't have ${YELLOW}hyprland${RED} package!${RESET}"
	read;exit 0
fi

echo -e "\n\033[38;5;46mConfigurations were successfully reloaded.${RESET}"

# Legacy.
# mpvpaper was removed due to waypaper usage.
# if exists mpvpaper;then
# 	kp mpvpaper
# 	video=$(zenity --file-selection --title="Select mpvpaper video"&>/dev/null)
# 	run mpvpaper -s -o "--loop --mute --no-osd-bar --no-input-default-bindings" ALL $video
# fi
