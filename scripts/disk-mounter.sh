#!/usr/bin/env bash
# Disk Mounter - easily mount your disks.
# ==============================================================================

GREEN="\e[32m"
FINISH="\033[38;5;46m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\x1B[36m"
RESET="\e[0m"

if [ $EUID -ne 0 ];then
    echo -e "${YELLOW}Elevation needed. Restarting with doas..${RESET}"
    exec doas bash "$0" "$@"
fi

title(){
    echo -e "\033[38;5;213mDiskMounter by\033[0m \033[38;5;171mal1h3n${RESET}"
    echo -e "Usage: ${BLUE}$0 ${GREEN}<device> ${YELLOW}<mount_path>${RESET}"
    echo -e "Example: ${BLUE}$0 ${GREEN}/dev/sda1 ${YELLOW}/mnt/mydisk${RESET}"
}

s(){ su - $USER -c "$*"; } # Launch as user.

mnt(){
    local dev=$1
    local pth=$2

    if [[ $dev != /dev/* ]];then
        dev=/dev/$dev
    fi

    if s mount --mkdir $dev $pth;then
        echo -e "${GREEN}✔ Device $dev mounted to $pth${RESET}"
    else
        echo -e "${RED}✖ Failed to mount $dev${RESET}"
        exit 1
    fi
}

gui(){
    echo -e "${RED}--- Interactive Mode ---${RESET}"

    local dev pth
    if command -v gum >/dev/null 2>&1;then
        dev=$(lsblk -rno NAME,SIZE,FSTYPE,LABEL 2>/dev/null \
            | awk '$3 != "" && $3 != "swap" {print "/dev/"$0}' \
            | gum choose --header "Device to mount:" | awk '{print $1}')
        [[ -n "$dev" ]] || { echo -e "${RED}✖ No device selected${RESET}"; exit 1; }
        pth=$(gum input --header "Mount path:" --value "/mnt/${dev##*/}")
    else
        read -rp "$(echo -e ${FINISH}Device\ \(e.g.\ /dev/sda1\): ${RESET})" dev
        read -rp "$(echo -e ${FINISH}Mount\ path\ \(e.g.\ /mnt/disk\): ${RESET})" pth
    fi

    if [[ -z "$dev" || -z "$pth" ]];then
        echo -e "${RED}✖ Invalid input${RESET}"
        exit 1
    fi

    mnt "$dev" "$pth"
}

if [[ -z $1 || -z "$2" ]];then
    title
    gui
else
    mnt $1 $2
fi