. /etc/os-release

case "$ID" in
    arch)
        icon=""
        ;;
    endeavouros)
        icon=""
        ;;
    manjaro)
        icon=""
        ;;
    ubuntu)
        icon=""
        ;;
    debian)
        icon=""
        ;;
    fedora)
        icon=""
        ;;
    alpine)
        icon=""
        ;;
    nixos)
        icon=" "
        ;;
    gentoo)
        icon=""
        ;;
    void)
        icon=""
        ;;
    opensuse*|suse)
        icon=""
        ;;
    rhel)
        icon=""
        ;;
    centos)
        icon=""
        ;;
    rocky)
        icon=""
        ;;
    almalinux)
        icon=""
        ;;
    *)
        # fallback: try ID_LIKE
        case "$ID_LIKE" in
            *arch*)
                icon=""
                ;;
            *debian*)
                icon=""
                ;;
            *rhel*|*fedora*)
                icon=""
                ;;
            *)
                icon=""
                ;;
        esac
        ;;
esac

echo " <span>$icon</span>"