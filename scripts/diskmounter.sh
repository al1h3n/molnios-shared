# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - ko-fi.com/al1h3n
# Disk Mounter v1 - first release.
# Easily mount your disks.
# ==============================================================================

mnt(){
    mount dev
    echo -e "Device $1 was mounted to the path $pth"
}

title(){

}

gui(){

}

dev = /dev/$1
pth = $2

if [ -z $1 ];then
    gui
fi

mnt dev, pth
