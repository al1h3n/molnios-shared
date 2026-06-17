wallpaper_list_static(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/static"
    if [[ -d "$wallpaper_dir" ]];then
        find "$wallpaper_dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | sort
    fi
}

wallpaper_list_video(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/video"
    if [[ -d "$wallpaper_dir" ]];then
        find "$wallpaper_dir" -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.gif" \) | sort
    fi
}

wallpaper_apply(){
    local wallpaper_path="$1"

    if exists waypaper;then
        waypaper --wallpaper "$wallpaper_path"
    elif exists hyprctl;then
        hyprctl hyprpaper preload "$wallpaper_path"
        hyprctl hyprpaper wallpaper ",$wallpaper_path"
    elif exists swaybg;then
        killall swaybg 2>/dev/null || true
        swaybg -i "$wallpaper_path" &
    elif exists feh;then
        feh --bg-fill "$wallpaper_path"
    fi
}

wallpaper_random(){
    local wallpapers
    mapfile -t wallpapers < <(wallpaper_list_static)
    if [[ ${#wallpapers[@]} -gt 0 ]];then
        local random_wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
        wallpaper_apply "$random_wp"
        notify "Random wallpaper: $(basename "$random_wp") ($(basename "$(dirname "$random_wp")"))"
    else
        notify_error "No static wallpapers found"
    fi
}

wallpaper_random_video(){
    local wallpapers
    mapfile -t wallpapers < <(wallpaper_list_video)
    if [[ ${#wallpapers[@]} -gt 0 ]];then
        local random_wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
        wallpaper_apply "$random_wp"
        notify "Random video wallpaper: $(basename "$random_wp") ($(basename "$(dirname "$random_wp")"))"
    else
        notify_error "No video wallpapers found"
    fi
}

wallpaper_menu_static(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/static"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_static)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No static wallpapers were found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Static Wallpapers" "Select a wallpaper:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    wallpaper_apply "${paths[$idx]}"
    notify "Wallpaper set: ${labels[$idx]}"
}

wallpaper_menu_video(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/video"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_video)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No video wallpapers were found"
        return
    fi

    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Video Wallpapers" "Select a video wallpaper:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    wallpaper_apply "${paths[$idx]}"
    notify "Video wallpaper set: ${labels[$idx]}"
}

# wallust backend.
_wallust_apply(){
    local wal_src="$1"
    local borderline_src="$2"

    if ! exists wallust;then
        notify_error "wallust not found"
        return 1
    fi

    wallust -C $L_PATH/config/theming/wallust.toml run -I background "$wal_src"

    local bscript="$L_PATH/scripts/borderline.sh"
    if [[ -f "$bscript" ]];then
        sh "$bscript" "$borderline_src"
    else
        notify_error "borderline.sh not found at $bscript"
    fi
}

wallust_colors_static(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/static"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_static)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No static images found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Wallust — Pick Source Image" "Select image for color generation:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    _wallust_apply "${paths[$idx]}" "${paths[$idx]}"
    notify "Wallust colors applied from: ${labels[$idx]}"
}

wallust_colors_video(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/video"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_video)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No video files found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Wallust — Pick Source Video" "Select video for color generation:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    local wp="${paths[$idx]}"
    local frame
    frame=$(_pywal_extract_frame "$wp")
    _wallust_apply "$frame" "$wp"
    rm -f "$frame"
    notify "Wallust colors applied from: ${labels[$idx]}"
}

wallpaper_random_static_wallust(){
    local wallpapers
    mapfile -t wallpapers < <(wallpaper_list_static)
    if [[ ${#wallpapers[@]} -eq 0 ]];then
        notify_error "No static wallpapers found"
        return
    fi
    local wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
    wallpaper_apply "$wp"
    _wallust_apply "$wp" "$wp"
    notify "Random static (wallust): $(basename "$wp")"
}

wallpaper_random_video_wallust(){
    local wallpapers
    mapfile -t wallpapers < <(wallpaper_list_video)
    if [[ ${#wallpapers[@]} -eq 0 ]];then
        notify_error "No video wallpapers found"
        return
    fi
    local wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
    wallpaper_apply "$wp"
    local frame
    frame=$(_pywal_extract_frame "$wp")
    _wallust_apply "$frame" "$wp"
    rm -f "$frame"
    notify "Random video (wallust): $(basename "$wp")"
}

wallpaper_menu_static_wallust(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/static"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_static)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No static wallpapers found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Static Wallpapers + Wallust" "Select a wallpaper:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    local wp="${paths[$idx]}"
    wallpaper_apply "$wp"
    _wallust_apply "$wp" "$wp"
    notify "Wallpaper set (wallust): ${labels[$idx]}"
}

wallpaper_menu_video_wallust(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/video"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_video)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No video wallpapers found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Video Wallpapers + Wallust" "Select a video wallpaper:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    local wp="${paths[$idx]}"
    wallpaper_apply "$wp"
    local frame
    frame=$(_pywal_extract_frame "$wp")
    _wallust_apply "$frame" "$wp"
    rm -f "$frame"
    notify "Video wallpaper set (wallust): ${labels[$idx]}"
}

# pywal16 (pywal) backend.

# Extract first video frame for pywal
_pywal_extract_frame(){
    local video="$1"
    local tmp=$(mktemp /tmp/molnios_wal_XXXXXX.png)
    # Fixed missing space before 2>/dev/null
    ffmpeg -i "$video" -y -vframes 1 -vf scale=480:270 -v quiet "$tmp" 2>/dev/null
    echo "$tmp"
}

# Core: run pywal then borderline.
_pywal_apply(){
    local wal_src="$1"
    local borderline_src="$2"

    if ! exists wal;then
        notify_error "pywal (wal) not found"
        return 1
    fi

    wal --recursive -i "$wal_src"

    local bscript="$L_PATH/scripts/borderline.sh"
    if [[ -f "$bscript" ]];then
        sh "$bscript" "$borderline_src"
    else
        notify_error "borderline.sh not found at $bscript"
    fi
}

wallpaper_random_static_pywal(){
    local wallpapers
    mapfile -t wallpapers < <(wallpaper_list_static)
    if [[ ${#wallpapers[@]} -eq 0 ]];then
        notify_error "No static wallpapers found"
        return
    fi
    local wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
    wallpaper_apply "$wp"
    _pywal_apply "$wp" "$wp"
    notify "Random static (pywal): $(basename "$wp")"
}

wallpaper_random_video_pywal(){
    local wallpapers
    mapfile -t wallpapers < <(wallpaper_list_video)
    if [[ ${#wallpapers[@]} -eq 0 ]];then
        notify_error "No video wallpapers found"
        return
    fi
    local wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
    wallpaper_apply "$wp"
    local frame
    frame=$(_pywal_extract_frame "$wp")
    _pywal_apply "$frame" "$wp"
    rm -f "$frame"
    notify "Random video (pywal): $(basename "$wp")"
}

wallpaper_menu_static_pywal(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/static"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_static)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No static wallpapers found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx=$(show_menu "Static Wallpapers + Pywal" "Select a wallpaper:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    local wp="${paths[$idx]}"
    wallpaper_apply "$wp"
    _pywal_apply "$wp" "$wp"
    notify "Wallpaper set (pywal): ${labels[$idx]}"
}

wallpaper_menu_video_pywal(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/video"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_video)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No video wallpapers found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx=$(show_menu "Video Wallpapers + Pywal" "Select a video wallpaper:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    local wp="${paths[$idx]}"
    wallpaper_apply "$wp"
    local frame=$(_pywal_extract_frame "$wp")
    _pywal_apply "$frame" "$wp"
    rm -f "$frame"
    notify "Video wallpaper set (pywal): ${labels[$idx]}"
}

# ─────────────────────────────────────────────────────────────────────────────
# matugen (Material You) backend.
# ─────────────────────────────────────────────────────────────────────────────

_matugen_apply(){
    local wal_src="$1"
    local borderline_src="$2"

    if ! exists matugen;then
        notify_error "matugen not found"
        return 1
    fi

    # Priority: env var → molnios-colors.conf → built-in default
    local _scheme="${MATUGEN_SCHEME:-}"
    local _mode="${MATUGEN_MODE:-}"
    local _conf="${XDG_CONFIG_HOME:-$HOME/.config}/molnios/config/theming/molnios-colors.conf"
    if [[ -f "$_conf" ]];then
        local _v
        _v=$(grep -E "^[[:space:]]*MATUGEN_SCHEME[[:space:]]*=" "$_conf" \
             | tail -n1 | cut -d= -f2- \
             | sed 's/[[:space:]]*#.*$//;s/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -z "$_scheme" && -n "$_v" ]] && _scheme="$_v"
        _v=$(grep -E "^[[:space:]]*MATUGEN_MODE[[:space:]]*=" "$_conf" \
             | tail -n1 | cut -d= -f2- \
             | sed 's/[[:space:]]*#.*$//;s/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -z "$_mode" && -n "$_v" ]] && _mode="$_v"
    fi

    matugen -t "${_scheme:-scheme-tonal-spot}" \
            -m "${_mode:-dark}" \
            -c $L_PATH/config/theming/matugen.toml \
            image "$wal_src"

    local bscript="$L_PATH/scripts/borderline.sh"
    if [[ -f "$bscript" ]];then
        sh "$bscript" "$borderline_src"
    else
        notify_error "borderline.sh not found at $bscript"
    fi
}

matugen_colors_static(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/static"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_static)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No static images found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Matugen — Pick Source Image" "Select image for color generation:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    _matugen_apply "${paths[$idx]}" "${paths[$idx]}"
    notify "Matugen colors applied from: ${labels[$idx]}"
}

matugen_colors_video(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/video"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_video)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No video files found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Matugen — Pick Source Video" "Select video for color generation:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    local wp="${paths[$idx]}"
    local frame
    frame=$(_pywal_extract_frame "$wp")
    _matugen_apply "$frame" "$wp"
    rm -f "$frame"
    notify "Matugen colors applied from: ${labels[$idx]}"
}

wallpaper_random_static_matugen(){
    local wallpapers
    mapfile -t wallpapers < <(wallpaper_list_static)
    if [[ ${#wallpapers[@]} -eq 0 ]];then
        notify_error "No static wallpapers found"
        return
    fi
    local wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
    wallpaper_apply "$wp"
    _matugen_apply "$wp" "$wp"
    notify "Random static (matugen): $(basename "$wp")"
}

wallpaper_random_video_matugen(){
    local wallpapers
    mapfile -t wallpapers < <(wallpaper_list_video)
    if [[ ${#wallpapers[@]} -eq 0 ]];then
        notify_error "No video wallpapers found"
        return
    fi
    local wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
    wallpaper_apply "$wp"
    local frame
    frame=$(_pywal_extract_frame "$wp")
    _matugen_apply "$frame" "$wp"
    rm -f "$frame"
    notify "Random video (matugen): $(basename "$wp")"
}

wallpaper_menu_static_matugen(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/static"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_static)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No static wallpapers found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Static Wallpapers + Matugen" "Select a wallpaper:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    local wp="${paths[$idx]}"
    wallpaper_apply "$wp"
    _matugen_apply "$wp" "$wp"
    notify "Wallpaper set (matugen): ${labels[$idx]}"
}

wallpaper_menu_video_matugen(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/video"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_video)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No video wallpapers found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Video Wallpapers + Matugen" "Select a video wallpaper:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    local wp="${paths[$idx]}"
    wallpaper_apply "$wp"
    local frame
    frame=$(_pywal_extract_frame "$wp")
    _matugen_apply "$frame" "$wp"
    rm -f "$frame"
    notify "Video wallpaper set (matugen): ${labels[$idx]}"
}