# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - ko-fi.com/al1h3n
# Disk Mounter - easily mount your disks.
# ==============================================================================

GREEN="\e[32m"
FINISH="\033[38;5;46m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\x1B[36m"
RESET="\e[0m"

if [ $EUID -ne 0 ];then
    echo -e "${YELLOW}Elevation needed. Restarting with sudo..${RESET}"
    exec sudo sh $0 $@
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

    read -rp "$(echo -e ${FINISH}Device\ \(e.g.\ /dev/sda1\): ${RESET})" dev
    read -rp "$(echo -e ${FINISH}Mount\ path\ \(e.g.\ /mnt/disk\): ${RESET})" pth

    if [[ -z "$dev" || -z "$pth" ]];then
        echo -e "${RED}✖ Invalid input${RESET}"
        exit 1
    fi

    mnt $dev $pth
}

if [[ -z $1 || -z "$2" ]];then
    title
    gui
else
    mnt $1 $2
fi