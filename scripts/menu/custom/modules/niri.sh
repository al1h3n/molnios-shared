# ─────────────────────────────────────────────────────────────────────────────
# NIRI CONFIG HELPERS
# ─────────────────────────────────────────────────────────────────────────────

_NIRI_CONFIG_DEFAULT="${HOME}/.config/niri/config.kdl"

# Follow symlinks — NixOS/home-manager symlinks ~/.config/niri/config.kdl into
# the mutable dotfiles repo; readlink -f gives us the real writable path.
_niri_config_path(){
    local raw="${NIRI_CONFIG_PATH:-${_NIRI_CONFIG_DEFAULT}}"
    readlink -f "$raw" 2>/dev/null || echo "$raw"
}

_niri_check(){
    local cfg
    cfg=$(_niri_config_path)
    [[ -f "$cfg" ]] || {
        notify_error "Niri config not found:\n${cfg}"
        return 1
    }
    [[ -w "$cfg" ]] || {
        notify_error "Niri config is read-only:\n${cfg}\nSet NIRI_CONFIG_PATH to your mutable source file."
        return 1
    }
}

_niri_backup(){
    local cfg
    cfg=$(_niri_config_path)
    cp "$cfg" "${cfg}.molnios.bak" 2>/dev/null || true
}

_niri_reload(){
    if niri msg action reload-config 2>/dev/null; then
        notify "Niri config reloaded"
    else
        notify_error "Niri config reload failed"
    fi
}

# Guard: fail with a notification if a named top-level block is absent.
_niri_require_block(){
    local block="$1"
    local cfg
    cfg=$(_niri_config_path)
    if ! grep -qE "^[[:space:]]*${block}[[:space:]]*\{" "$cfg"; then
        notify_error "No '${block} {}' block found in config.\nAdd the block to use this toggle."
        return 1
    fi
}

# ── Low-level KDL block editors (awk) ────────────────────────────────────────
#
# Depth is tracked BEFORE the increment on each line, so depth==1 inside the
# awk body refers to direct children of the enclosing block.  The block-open
# line ("layout {") is matched at depth==0 (before depth becomes 1).
#
# gsub(/\{/,"",tmp) returns the count of substitutions without touching $0.
# ─────────────────────────────────────────────────────────────────────────────

# Replace "KEY VALUE" at depth-1 inside a named top-level block.
# _niri_set_in_block BLOCK KEY VALUE
_niri_set_in_block(){
    local block="$1" key="$2" value="$3"
    local cfg
    cfg=$(_niri_config_path)
    awk -v BLK="$block" -v KEY="$key" -v VAL="$value" '
    BEGIN { in_blk=0; depth=0; done=0 }
    {
        tmp=$0; opens=gsub(/\{/,"",tmp)
        tmp=$0; closes=gsub(/\}/,"",tmp)

        if (!in_blk && depth==0 && $0 ~ ("^[[:space:]]*" BLK "([[:space:]]|\\{)") && opens>0)
            in_blk=1

        if (in_blk && depth==1 && !done && $1==KEY) {
            match($0,/^[[:space:]]*/); ind=substr($0,1,RLENGTH)
            $0 = ind KEY " " VAL
            done=1
        }

        depth += opens - closes
        if (depth==0) in_blk=0
        print
    }' "$cfg" > "${cfg}.tmp" && mv "${cfg}.tmp" "$cfg"
}

# Replace "KEY VALUE" at depth-2 inside SUB, which is a sub-block of BLOCK.
# _niri_set_in_subblock BLOCK SUB KEY VALUE
_niri_set_in_subblock(){
    local block="$1" sub="$2" key="$3" value="$4"
    local cfg
    cfg=$(_niri_config_path)
    awk -v BLK="$block" -v SUB="$sub" -v KEY="$key" -v VAL="$value" '
    BEGIN { in_blk=0; in_sub=0; depth=0; done=0 }
    {
        tmp=$0; opens=gsub(/\{/,"",tmp)
        tmp=$0; closes=gsub(/\}/,"",tmp)

        if (!in_blk && depth==0 && $0 ~ ("^[[:space:]]*" BLK "([[:space:]]|\\{)") && opens>0)
            in_blk=1
        if (in_blk && !in_sub && depth==1 && $0 ~ ("^[[:space:]]*" SUB "[[:space:]]*\\{") && opens>0)
            in_sub=1

        if (in_sub && depth==2 && !done && $1==KEY) {
            match($0,/^[[:space:]]*/); ind=substr($0,1,RLENGTH)
            $0 = ind KEY " " VAL
            done=1
        }

        depth += opens - closes
        if (in_sub  && depth<=1) in_sub=0
        if (depth==0)            in_blk=0
        print
    }' "$cfg" > "${cfg}.tmp" && mv "${cfg}.tmp" "$cfg"
}

# Toggle a bare-keyword flag inside a named top-level block.
# "off", "xray", "always-center-single-column", etc.
# Prints "on"  when the flag was just added (feature now ON in Niri's terms),
# prints "off" when the flag was just removed.
_niri_toggle_block_flag(){
    local block="$1" flag="$2"
    local cfg
    cfg=$(_niri_config_path)

    local present
    present=$(awk -v BLK="$block" -v FLAG="$flag" '
    BEGIN { in_blk=0; depth=0 }
    {
        tmp=$0; opens=gsub(/\{/,"",tmp)
        tmp=$0; closes=gsub(/\}/,"",tmp)
        if (!in_blk && depth==0 && $0 ~ ("^[[:space:]]*" BLK "([[:space:]]|\\{)") && opens>0)
            in_blk=1
        if (in_blk && depth==1 && $0 ~ ("^[[:space:]]*" FLAG "[[:space:]]*$")) {
            print "yes"; exit
        }
        depth += opens - closes
        if (depth==0) in_blk=0
    }' "$cfg")

    if [[ "$present" == "yes" ]]; then
        # Flag exists → remove it
        awk -v BLK="$block" -v FLAG="$flag" '
        BEGIN { in_blk=0; depth=0; done=0 }
        {
            tmp=$0; opens=gsub(/\{/,"",tmp)
            tmp=$0; closes=gsub(/\}/,"",tmp)
            if (!in_blk && depth==0 && $0 ~ ("^[[:space:]]*" BLK "([[:space:]]|\\{)") && opens>0)
                in_blk=1
            if (in_blk && depth==1 && !done && $0 ~ ("^[[:space:]]*" FLAG "[[:space:]]*$")) {
                done=1; depth += opens-closes; next
            }
            depth += opens - closes
            if (depth==0) in_blk=0
            print
        }' "$cfg" > "${cfg}.tmp" && mv "${cfg}.tmp" "$cfg"
        echo "off"
    else
        # Flag absent → insert it on the line after the block's opening brace
        awk -v BLK="$block" -v FLAG="$flag" '
        BEGIN { done=0 }
        !done && $0 ~ ("^[[:space:]]*" BLK "([[:space:]]|\\{)") && /\{/ {
            print
            match($0,/^[[:space:]]*/); ind=substr($0,1,RLENGTH) "    "
            print ind FLAG
            done=1; next
        }
        { print }' "$cfg" > "${cfg}.tmp" && mv "${cfg}.tmp" "$cfg"
        echo "on"
    fi
}

# Toggle a bare keyword at the very top level of the config (no enclosing block).
_niri_toggle_top_flag(){
    local flag="$1"
    local cfg
    cfg=$(_niri_config_path)
    if grep -qE "^[[:space:]]*${flag}[[:space:]]*$" "$cfg"; then
        sed -i "/^[[:space:]]*${flag}[[:space:]]*$/d" "$cfg"
        echo "off"
    else
        echo "$flag" >> "$cfg"
        echo "on"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# NIRI LAYOUT FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────

niri_adjust_gaps(){
    _niri_check || return
    local cfg
    cfg=$(_niri_config_path)

    local current
    current=$(awk '
    BEGIN { in_layout=0; depth=0 }
    {
        tmp=$0; opens=gsub(/\{/,"",tmp); tmp=$0; closes=gsub(/\}/,"",tmp)
        if (!in_layout && depth==0 && /^layout[[:space:]]*\{/ && opens>0) in_layout=1
        if (in_layout && depth==1 && $1=="gaps") { print $2; exit }
        depth += opens-closes
        if (depth==0) in_layout=0
    }' "$cfg")

    local new_val
    new_val=$(show_input "Niri — Gaps" \
        "Gap between windows and the screen edge (pixels):" \
        "${current:-16}")
    [[ -z "$new_val" ]] && return
    [[ ! "$new_val" =~ ^[0-9]+(\.[0-9]+)?$ ]] && { notify_error "Invalid value: $new_val"; return; }

    _niri_backup
    _niri_set_in_block "layout" "gaps" "$new_val"
    _niri_reload
    notify "Gaps → ${new_val}px"
}

niri_adjust_border_width(){
    _niri_check || return
    local cfg
    cfg=$(_niri_config_path)
    local current
    current=$(sed -n '/^\s*border\s*{/,/^\s*}/{
        /^\s*width\s/{ s/^\s*width\s\+\([0-9.]*\).*/\1/; p; q }
    }' "$cfg")

    local new_val
    new_val=$(show_input "Niri — Border Width" \
        "Inactive window border width (pixels):" \
        "${current:-4}")
    [[ -z "$new_val" ]] && return
    [[ ! "$new_val" =~ ^[0-9]+(\.[0-9]+)?$ ]] && { notify_error "Invalid value: $new_val"; return; }

    _niri_backup
    _niri_set_in_subblock "layout" "border" "width" "$new_val"
    _niri_reload
    notify "Border width → ${new_val}px"
}

niri_adjust_focus_ring_width(){
    _niri_check || return
    local cfg
    cfg=$(_niri_config_path)
    local current
    current=$(sed -n '/^\s*focus-ring\s*{/,/^\s*}/{
        /^\s*width\s/{ s/^\s*width\s\+\([0-9.]*\).*/\1/; p; q }
    }' "$cfg")

    local new_val
    new_val=$(show_input "Niri — Focus Ring Width" \
        "Active window focus ring width (pixels):" \
        "${current:-4}")
    [[ -z "$new_val" ]] && return
    [[ ! "$new_val" =~ ^[0-9]+(\.[0-9]+)?$ ]] && { notify_error "Invalid value: $new_val"; return; }

    _niri_backup
    _niri_set_in_subblock "layout" "focus-ring" "width" "$new_val"
    _niri_reload
    notify "Focus ring width → ${new_val}px"
}

# ─────────────────────────────────────────────────────────────────────────────
# NIRI EFFECTS FUNCTIONS
#
# Assumes top-level blocks in config.kdl:
#
#   blur {
#       // off        ← bare flag: present = blur disabled
#       radius 10
#       passes 2
#       noise  0.1
#       saturation 1.0
#       xray         ← bare flag: present = see-through mode on
#   }
#
#   shadow {
#       // off        ← bare flag: present = shadow disabled
#       softness 30
#       spread 5
#       offset x=0 y=5
#       color "#00000070"
#   }
#
# Adjust block/key names if your Niri 26.x release uses different identifiers.
# ─────────────────────────────────────────────────────────────────────────────

niri_toggle_blur(){
    _niri_check            || return
    _niri_require_block "blur" || return
    _niri_backup
    local state
    state=$(_niri_toggle_block_flag "blur" "off")
    _niri_reload
    # "off" flag added   → blur disabled;  removed → blur enabled
    [[ "$state" == "on" ]] && notify "Blur: disabled" || notify "Blur: enabled"
}

niri_toggle_shadow(){
    _niri_check              || return
    _niri_require_block "shadow" || return
    _niri_backup
    local state
    state=$(_niri_toggle_block_flag "shadow" "off")
    _niri_reload
    [[ "$state" == "on" ]] && notify "Shadow: disabled" || notify "Shadow: enabled"
}

niri_toggle_xray(){
    _niri_check            || return
    _niri_require_block "blur" || return
    _niri_backup
    # "xray" flag present = see-through mode on
    local state
    state=$(_niri_toggle_block_flag "blur" "xray")
    _niri_reload
    notify "Blur xray (see-through): $state"
}

niri_blur_saturation(){
    _niri_check            || return
    _niri_require_block "blur" || return
    local cfg
    cfg=$(_niri_config_path)
    local current
    current=$(sed -n '/^\s*blur\s*{/,/^\s*}/{
        /^\s*saturation\s/{ s/^\s*saturation\s\+\([0-9.]*\).*/\1/; p; q }
    }' "$cfg")

    local new_val
    new_val=$(show_input "Niri — Blur Saturation" \
        "Color saturation of blurred content:\n  0.0 = grayscale   1.0 = natural   >1.0 = vivid" \
        "${current:-1.0}")
    [[ -z "$new_val" ]] && return
    [[ ! "$new_val" =~ ^[0-9]+(\.[0-9]+)?$ ]] && { notify_error "Invalid value: $new_val"; return; }

    _niri_backup
    _niri_set_in_block "blur" "saturation" "$new_val"
    _niri_reload
    notify "Blur saturation → $new_val"
}

niri_blur_noise(){
    _niri_check            || return
    _niri_require_block "blur" || return
    local cfg
    cfg=$(_niri_config_path)
    local current
    current=$(sed -n '/^\s*blur\s*{/,/^\s*}/{
        /^\s*noise\s/{ s/^\s*noise\s\+\([0-9.]*\).*/\1/; p; q }
    }' "$cfg")

    local new_val
    new_val=$(show_input "Niri — Blur Noise" \
        "Grain/noise texture on blurred surfaces (0.0–1.0):" \
        "${current:-0.1}")
    [[ -z "$new_val" ]] && return
    [[ ! "$new_val" =~ ^[0-9]+(\.[0-9]+)?$ ]] && { notify_error "Invalid value: $new_val"; return; }

    _niri_backup
    _niri_set_in_block "blur" "noise" "$new_val"
    _niri_reload
    notify "Blur noise → $new_val"
}

# ─────────────────────────────────────────────────────────────────────────────
# NIRI DISPLAY FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────

# List connector names from niri IPC.
_niri_list_outputs(){
    niri msg --json outputs 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else [{'name': k, **v} for k, v in d.items()]
    for o in items:
        n = o.get('name', '')
        if n: print(n)
except: sys.exit(1)
" 2>/dev/null
}

# List modes for one output — current mode is tagged with *.
_niri_list_modes(){
    local output="$1"
    niri msg --json outputs 2>/dev/null | python3 -c "
import json, sys
target = '$output'
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else [{'name': k, **v} for k, v in d.items()]
    for o in items:
        if o.get('name') != target:
            continue
        modes = o.get('modes', [])
        cur   = o.get('current_mode')
        # current_mode can be an int index or a full dict depending on niri version
        if isinstance(cur, int):
            cur = modes[cur] if 0 <= cur < len(modes) else {}
        elif not isinstance(cur, dict):
            cur = {}
        for m in modes:
            rr  = m.get('refresh_rate', 0) / 1000.0
            tag = ' *' if (m.get('width')        == cur.get('width')        and
                           m.get('height')       == cur.get('height')       and
                           m.get('refresh_rate') == cur.get('refresh_rate')) else ''
            print(f\"{m['width']}x{m['height']}@{rr:.3f}{tag}\")
except: sys.exit(1)
" 2>/dev/null
}

# Current fractional scale for an output.
_niri_current_scale(){
    local output="$1"
    niri msg --json outputs 2>/dev/null | python3 -c "
import json, sys
target = '$output'
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else [{'name': k, **v} for k, v in d.items()]
    for o in items:
        if o.get('name') == target:
            scale = (o.get('logical') or {}).get('scale') or o.get('scale') or 1.0
            print(scale); sys.exit(0)
    print(1.0)
except: print(1.0)
" 2>/dev/null
}

# Interactive output picker; echoes connector name to stdout.
_niri_select_output(){
    local -a outputs
    mapfile -t outputs < <(_niri_list_outputs)
    [[ ${#outputs[@]} -eq 0 ]] && { notify_error "No outputs detected by niri"; return 1; }
    [[ ${#outputs[@]} -eq 1 ]] && { echo "${outputs[0]}"; return 0; }
    local idx
    idx=$(show_menu "Select Output" "Choose display output:" "${outputs[@]}")
    [[ -z "$idx" || ! "$idx" =~ ^[0-9]+$ ]] && return 1
    echo "${outputs[$idx]}"
}

# Edit a key inside an  output "NAME" { }  block in the config file.
_niri_set_output_val(){
    local output="$1" key="$2" value="$3"
    local cfg
    cfg=$(_niri_config_path)
    awk -v OUT="$output" -v KEY="$key" -v VAL="$value" '
    BEGIN { in_out=0; depth=0; done=0 }
    {
        tmp=$0; opens=gsub(/\{/,"",tmp)
        tmp=$0; closes=gsub(/\}/,"",tmp)

        if (!in_out && depth==0 && $0 ~ ("^output[[:space:]]+\"" OUT "\"") && opens>0)
            in_out=1

        if (in_out && depth==1 && !done && $1==KEY) {
            match($0,/^[[:space:]]*/); ind=substr($0,1,RLENGTH)
            $0 = ind KEY " " VAL
            done=1
        }

        depth += opens - closes
        if (depth==0) in_out=0
        print
    }' "$cfg" > "${cfg}.tmp" && mv "${cfg}.tmp" "$cfg"
}

niri_set_scale(){
    _niri_check || return
    local output
    output=$(_niri_select_output) || return
    local current
    current=$(_niri_current_scale "$output")

    local new_scale
    new_scale=$(show_input "Niri — Scale ($output)" \
        "HiDPI scale factor for $output.\nExamples: 1, 1.25, 1.5, 2\n0 — reload config (restore saved value)" \
        "${current:-1}")
    [[ -z "$new_scale" ]] && return
    new_scale=$(printf '%s' "$new_scale" | tr -d '[:space:]')

    if [[ "$new_scale" == "0" ]]; then
        _niri_reload
        return
    fi
    [[ ! "$new_scale" =~ ^[0-9]+(\.[0-9]+)?$ ]] && {
        notify_error "Invalid scale: $new_scale"
        return
    }
    _niri_backup
    _niri_set_output_val "$output" "scale" "$new_scale"
    _niri_reload
    notify "$output → scale $new_scale"
}

niri_set_resolution(){
    _niri_check || return
    local output
    output=$(_niri_select_output) || return

    local -a modes
    mapfile -t modes < <(_niri_list_modes "$output")
    [[ ${#modes[@]} -eq 0 ]] && {
        notify_error "No modes available for $output"
        return
    }

    local idx
    idx=$(show_menu "Niri — Resolution ($output)" \
        "Select display mode  (* = current):" "${modes[@]}")
    [[ -z "$idx" || ! "$idx" =~ ^[0-9]+$ ]] && return

    local chosen="${modes[$idx]% \*}"   # strip the " *" current-mode marker
    _niri_backup
    _niri_set_output_val "$output" "mode" "\"$chosen\""
    _niri_reload
    notify "$output → $chosen"
}

# ─────────────────────────────────────────────────────────────────────────────
# NIRI OVERVIEW FUNCTIONS
#
# These assume a top-level "overview { }" block exists in config.kdl.
# If Niri 26.x does not expose such a block, remove the niri_overview
# register_menu and its two entries from the preset.
# ─────────────────────────────────────────────────────────────────────────────

niri_toggle_overview_blur(){
    _niri_check                  || return
    _niri_require_block "overview" || return
    _niri_backup
    local state
    state=$(_niri_toggle_block_flag "overview" "backdrop-blur-off")
    _niri_reload
    [[ "$state" == "on" ]] && notify "Overview backdrop blur: disabled" \
                           || notify "Overview backdrop blur: enabled"
}

niri_toggle_overview_effects(){
    _niri_check                  || return
    _niri_require_block "overview" || return
    _niri_backup
    local state
    state=$(_niri_toggle_block_flag "overview" "off")
    _niri_reload
    [[ "$state" == "on" ]] && notify "Overview effects: disabled" \
                           || notify "Overview effects: enabled"
}

# ─────────────────────────────────────────────────────────────────────────────
# NIRI MISC FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────

niri_toggle_center_column(){
    _niri_check || return
    local cfg
    cfg=$(_niri_config_path)

    local current
    current=$(awk '
    BEGIN { in_layout=0; depth=0 }
    {
        tmp=$0; opens=gsub(/\{/,"",tmp); tmp=$0; closes=gsub(/\}/,"",tmp)
        if (!in_layout && depth==0 && /^layout[[:space:]]*\{/ && opens>0) in_layout=1
        if (in_layout && depth==1 && $1=="center-focused-column") {
            match($0,/"[^"]*"/); print substr($0,RSTART+1,RLENGTH-2); exit
        }
        depth += opens-closes
        if (depth==0) in_layout=0
    }' "$cfg")

    local -a opts=("never" "always" "on-overflow")
    local idx
    idx=$(show_menu "Niri — Center Focused Column" \
        "Current: ${current:-never}\nChoose centering behaviour:" "${opts[@]}")
    [[ -z "$idx" || ! "$idx" =~ ^[0-9]+$ ]] && return

    local new_val="${opts[$idx]}"
    _niri_backup
    _niri_set_in_block "layout" "center-focused-column" "\"$new_val\""
    _niri_reload
    notify "center-focused-column → $new_val"
}

niri_toggle_single_column_center(){
    _niri_check || return
    local cfg
    cfg=$(_niri_config_path)

    local present
    present=$(awk '
    BEGIN { in_layout=0; depth=0 }
    {
        tmp=$0; opens=gsub(/\{/,"",tmp); tmp=$0; closes=gsub(/\}/,"",tmp)
        if (!in_layout && depth==0 && /^layout[[:space:]]*\{/ && opens>0) in_layout=1
        if (in_layout && depth==1 && /^\s*always-center-single-column\s*$/) { print "yes"; exit }
        depth += opens-closes
        if (depth==0) in_layout=0
    }' "$cfg")

    _niri_backup
    if [[ "$present" == "yes" ]]; then
        # Remove flag from layout block
        awk '
        BEGIN { in_layout=0; depth=0; done=0 }
        {
            tmp=$0; opens=gsub(/\{/,"",tmp); tmp=$0; closes=gsub(/\}/,"",tmp)
            if (!in_layout && depth==0 && /^layout[[:space:]]*\{/ && opens>0) in_layout=1
            if (in_layout && depth==1 && !done && /^\s*always-center-single-column\s*$/) {
                done=1; depth += opens-closes; next
            }
            depth += opens-closes
            if (depth==0) in_layout=0
            print
        }' "$cfg" > "${cfg}.tmp" && mv "${cfg}.tmp" "$cfg"
        notify "always-center-single-column: disabled"
    else
        # Inject on the first line inside the layout block
        awk '
        BEGIN { added=0 }
        !added && /^layout[[:space:]]*\{/ {
            print
            print "    always-center-single-column"
            added=1; next
        }
        { print }' "$cfg" > "${cfg}.tmp" && mv "${cfg}.tmp" "$cfg"
        notify "always-center-single-column: enabled"
    fi
    _niri_reload
}

niri_toggle_prefer_no_csd(){
    _niri_check || return
    _niri_backup
    local state
    state=$(_niri_toggle_top_flag "prefer-no-csd")
    _niri_reload
    notify "prefer-no-csd: $state"
}
