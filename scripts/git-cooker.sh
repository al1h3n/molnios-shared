#!/usr/bin/env bash

# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - ko-fi.com/al1h3n
# Git Cooker - AIO tool for git based on gum + fzf.

# ==============================================================================
#  Colors (Gruvbox Theme)
# ==============================================================================
GREEN=$'\033[38;5;142m'
FINISH=$'\033[38;5;100m'
YELLOW=$'\033[38;5;214m'
RED=$'\033[38;5;167m'
BLUE=$'\033[38;5;108m'
WHITE=$'\033[38;5;223m'
BG=$'\033[48;5;235m'
RESET=$'\033[0m'

# Check for TrueColor support
if [[ $COLORTERM =~ ^(truecolor|24bit)$ ]]; then
    GREEN=$'\033[38;2;184;187;38m'
    FINISH=$'\033[38;2;152;151;26m'
    YELLOW=$'\033[38;2;250;189;47m'
    RED=$'\033[38;2;251;73;52m'
    BLUE=$'\033[38;2;142;192;124m'
    WHITE=$'\033[38;2;235;219;178m'
    BG=$'\033[48;2;40;40;40m'
fi

# Additional variables used by the repo() function
_BLD=$'\033[1m'
_RST=$RESET
_YLW=$YELLOW
_CYN=$'\033[38;5;108m'

# Gum hex colors for styling interactive components natively
export GUM_CHOOSE_CURSOR_FOREGROUND="#fabd2f"     # Yellow
export GUM_CHOOSE_ITEM_FOREGROUND="#ebdbb2"       # White
export GUM_CHOOSE_SELECTED_FOREGROUND="#b8bb26"   # Green
export GUM_INPUT_PROMPT_FOREGROUND="#fabd2f"
export GUM_INPUT_CURSOR_FOREGROUND="#fabd2f"
export GUM_CONFIRM_SELECTED_BACKGROUND="#b8bb26"
export GUM_CONFIRM_UNSELECTED_BACKGROUND="#282828"
export GUM_CONFIRM_SELECTED_FOREGROUND="#282828"

# ==============================================================================
#  Setup & Environment
# ==============================================================================
# Resolving Real User (avoids caching to /root/.cache if executed via sudo/doas)
REAL_USER=${SUDO_USER:-${DOAS_USER:-$USER}}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6 2>/dev/null)
REAL_HOME=${REAL_HOME:-$HOME}

CACHE_DIR="$REAL_HOME/.cache/gitcooker"
mkdir -p "$CACHE_DIR"
CACHE_FILE="$CACHE_DIR/repos.txt"

# Identify absolute path to this script for fzf bindings
if [[ "$0" == /* ]]; then
    SCRIPT_PATH="$0"
elif command -v "$0" &> /dev/null; then
    SCRIPT_PATH=$(command -v "$0")
else
    SCRIPT_PATH="$(pwd)/$0"
fi

title() {
    echo -e "\033[38;5;213mGitCooker by\033[0m \033[38;5;171mal1h3n${RESET}"
    echo ""
}

s() { su - "$REAL_USER" -c "$*"; } # Launch as user

clone()  { repo --force "$@"; }
remove() { rm -rf "$@"; }
upload() { git push -u "$1"; }

# ==============================================================================
#  Shared Repo Function (Unmodified)
# ==============================================================================
repo() {
    # ------------------------------------------------------------------ #
    #  Colour helpers                                                      #
    # ------------------------------------------------------------------ #
    _info()    { echo -e "${BLUE}[repo]${RESET} $*"; }
    _ok()      { echo -e "${GREEN}[repo]${RESET} $*"; }
    _warn()    { echo -e "${YELLOW}[repo]${RESET} $*"; }
    _err()     { echo -e "${RED}[repo]${RESET} $*" >&2; }
    _section() { echo -e "${WHITE}── $* ──${RESET}"; }

    # ------------------------------------------------------------------ #
    #  Help                                                               #
    # ------------------------------------------------------------------ #
    _usage() {
        echo -e "
${_BLD}Usage:${_RST}
  repo LINK PATH [--file <path>] [--dir <path>] [--force]

${_BLD}Arguments:${_RST}
  LINK    Repo URL without ${_YLW}https://${_RST} and without ${_YLW}.git${_RST}
          e.g. ${_CYN}github.com/user/project${_RST}
  PATH    Local destination directory

${_BLD}Options:${_RST}
  --file  <remote-path>   Download only a single file from the repo
  --dir   <remote-path>   Download and extract a single directory from the repo
  --force                 Re-clone when the local repo is outdated
  -h, --help              Show this message
"
    }

    # ------------------------------------------------------------------ #
    #  Argument parsing                                                   #
    # ------------------------------------------------------------------ #
    local LINK="" DEST="" REMOTE_FILE="" REMOTE_DIR="" FORCE=false

    if [[ $# -eq 0 ]]; then _usage; return 0; fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)   _usage; return 0 ;;
            --force)     FORCE=true;         shift ;;
            --file)
                [[ -z "${2:-}" ]] && { _err "--file requires an argument"; return 1; }
                REMOTE_FILE="$2";            shift 2 ;;
            --dir)
                [[ -z "${2:-}" ]] && { _err "--dir requires an argument"; return 1; }
                REMOTE_DIR="$2";             shift 2 ;;
            -*)
                _err "Unknown option: $1"; _usage; return 1 ;;
            *)
                if   [[ -z "$LINK" ]]; then LINK="$1"
                elif [[ -z "$DEST" ]]; then DEST="$1"
                else _err "Unexpected argument: $1"; _usage; return 1
                fi
                shift ;;
        esac
    done

    # ------------------------------------------------------------------ #
    #  Validate                                                           #
    # ------------------------------------------------------------------ #
    [[ -z "$LINK" ]] && { _err "LINK is required."; _usage; return 1; }
    [[ -z "$DEST" ]] && { _err "PATH is required."; _usage; return 1; }

    if [[ -n "$REMOTE_FILE" && -n "$REMOTE_DIR" ]]; then
        _err "--file and --dir are mutually exclusive."
        return 1
    fi

    # Ensure git is available
    if ! command -v git &>/dev/null; then
        _err "git is not installed or not in PATH."
        return 1
    fi

    # ------------------------------------------------------------------ #
    #  Build clone URL                                                    #
    # ------------------------------------------------------------------ #
    local CLEAN_LINK="${LINK#https://}"
    CLEAN_LINK="${CLEAN_LINK%.git}"
    local CLONE_URL="https://${CLEAN_LINK}.git"

    _section "repo"
    _info "Source : ${_BLD}${CLONE_URL}${_RST}"
    _info "Dest   : ${_BLD}${DEST}${_RST}"
    [[ -n "$REMOTE_FILE" ]] && _info "File   : ${_BLD}${REMOTE_FILE}${_RST}"
    [[ -n "$REMOTE_DIR"  ]] && _info "Dir    : ${_BLD}${REMOTE_DIR}${_RST}"
    [[ "$FORCE" == true   ]] && _info "Force  : ${_YLW}enabled${_RST}"

    # ------------------------------------------------------------------ #
    #  Helper — fetch remote HEAD commit SHA                              #
    # ------------------------------------------------------------------ #
    _remote_head() {
        git ls-remote "$1" HEAD 2>/dev/null | awk '$2 == "HEAD" {print $1; exit}'
    }

    # ------------------------------------------------------------------ #
    #  Mode A — full clone (no --file / --dir)                           #
    # ------------------------------------------------------------------ #
    if [[ -z "$REMOTE_FILE" && -z "$REMOTE_DIR" ]]; then

        if [[ -d "$DEST" ]]; then
            _info "Existing repo detected at '${DEST}'."

            local LOCAL_SHA REMOTE_SHA
            LOCAL_SHA=""
            [[ -f "$DEST/.repo_commit" ]] && LOCAL_SHA="$(cat "$DEST/.repo_commit")"
            REMOTE_SHA="$(_remote_head "$CLONE_URL")"

            if [[ -z "$REMOTE_SHA" ]]; then
                _warn "Could not reach remote — leaving repo untouched."
                return 0
            fi

            if [[ "$LOCAL_SHA" == "$REMOTE_SHA" ]]; then
                _ok "Already up to date (${LOCAL_SHA:0:8}). Nothing to do."
                return 0
            fi

            _warn "Outdated  local=${LOCAL_SHA:0:8}  remote=${REMOTE_SHA:0:8}"

            if [[ "$FORCE" != true ]]; then
                _warn "Use ${_BLD}--force${_RST} to re-clone. Leaving repo as-is."
                return 0
            fi

            _info "Removing outdated repo…"
            rm -rf "$DEST"
        fi

        _info "Cloning…"
        if git clone --depth 1 --filter=blob:none "$CLONE_URL" "$DEST"; then
            local FINAL_SHA
            FINAL_SHA="$(git -C "$DEST" rev-parse HEAD 2>/dev/null)"
            rm -rf "$DEST/.git"
            echo "$FINAL_SHA" > "$DEST/.repo_commit"
            _ok "Done → '${DEST}' (no .git, commit cached: ${FINAL_SHA:0:8})"
        else
            _err "git clone failed."
            return 1
        fi

        return 0
    fi

    # ------------------------------------------------------------------ #
    #  Mode B — sparse / file extraction (--file or --dir)               #
    # ------------------------------------------------------------------ #
    local TMP_DIR
    TMP_DIR="$(mktemp -d "/tmp/repo_XXXXXXXX")"

    _cleanup() { rm -rf "$TMP_DIR"; }
    trap _cleanup RETURN INT TERM

    local REMOTE_PATH
    if [[ -n "$REMOTE_FILE" ]]; then
        REMOTE_PATH="$REMOTE_FILE"
    else
        REMOTE_PATH="$REMOTE_DIR"
    fi

    if [[ -e "$DEST" ]]; then
        _info "Target path '${DEST}' already exists. Checking remote commit…"

        local REMOTE_SHA
        REMOTE_SHA="$(_remote_head "$CLONE_URL")"

        local SHA_STORE
        if [[ -d "$DEST" ]]; then
            SHA_STORE="${DEST%/}/.repo_commit"
        else
            SHA_STORE="${DEST}.repo_commit"
        fi

        local STORED_SHA=""
        [[ -f "$SHA_STORE" ]] && STORED_SHA="$(cat "$SHA_STORE")"

        if [[ -n "$REMOTE_SHA" && "$STORED_SHA" == "$REMOTE_SHA" ]]; then
            _ok "Already up to date (${REMOTE_SHA:0:8}). Nothing to do."
            return 0
        fi

        if [[ -n "$REMOTE_SHA" && -n "$STORED_SHA" ]]; then
            _warn "Outdated  local=${STORED_SHA:0:8}  remote=${REMOTE_SHA:0:8}"
            if [[ "$FORCE" != true ]]; then
                _warn "Use ${_BLD}--force${_RST} to re-download. Leaving as-is."
                return 0
            fi
            _info "Re-downloading…"
        fi
    fi

    _info "Initialising sparse clone in temp dir…"

    git clone \
        --filter=blob:none \
        --no-checkout \
        --depth 1 \
        "$CLONE_URL" "$TMP_DIR" 2>&1 | sed "s/^/  /"

    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
        _err "Sparse clone failed."
        return 1
    fi

    git -C "$TMP_DIR" sparse-checkout init --cone 2>/dev/null \
        || git -C "$TMP_DIR" sparse-checkout init

    git -C "$TMP_DIR" sparse-checkout set "$REMOTE_PATH"
    git -C "$TMP_DIR" checkout 2>&1 | sed "s/^/  /"

    local SRC_PATH="${TMP_DIR}/${REMOTE_PATH}"
    if [[ ! -e "$SRC_PATH" ]]; then
        _err "Path '${REMOTE_PATH}' was not found in the repository."
        return 1
    fi

    mkdir -p "$(dirname "$DEST")"

    if [[ -n "$REMOTE_FILE" ]]; then
        cp "$SRC_PATH" "$DEST"
        _ok "File saved → '${DEST}'"
    else
        mkdir -p "$DEST"
        cp -r "${SRC_PATH}/." "$DEST/"
        _ok "Directory extracted → '${DEST}'"
    fi

    local FINAL_SHA
    FINAL_SHA="$(git -C "$TMP_DIR" rev-parse HEAD 2>/dev/null)"

    local SHA_STORE
    if [[ -d "$DEST" ]]; then
        SHA_STORE="${DEST%/}/.repo_commit"
    else
        SHA_STORE="${DEST}.repo_commit"
    fi

    echo "$FINAL_SHA" > "$SHA_STORE"
    _info "Commit cached (${FINAL_SHA:0:8}) → '${SHA_STORE}'"

    return 0
}

# ==============================================================================
#  AIO Frontend Functions
# ==============================================================================
update_cache() {
    clear
    title
    echo -e "${YELLOW}Finding .git directories and updating cache...${RESET}"

    # Exclude typical mount points and hidden system dirs to significantly increase performance
    fd -H '^\.git$' "$REAL_HOME" / -t d -a -E /proc -E /sys -E /dev -E /mnt -E /run 2>/dev/null | \
        sed 's#/\.git/*$##' | \
        sort -u > "$CACHE_FILE"

    echo -e "${GREEN}Cache updated successfully!${RESET}"
    sleep 1
}

manage_mirrors() {
    while true; do
        clear
        title
        echo -e "${BLUE}Mirrors for:${RESET} ${WHITE}$(pwd)${RESET}\n"
        git remote -v
        echo ""

        local m_choice
        m_choice=$(gum choose --cursor="> " "Add Remote" "Remove Remote" "Change Remote URL" "Back")

        case "$m_choice" in
            "Add Remote")
                local r_name
                r_name=$(gum input --prompt="Remote name (e.g., origin): ")
                [[ -z "$r_name" ]] && continue
                local r_url
                r_url=$(gum input --prompt="Remote URL: ")
                [[ -z "$r_url" ]] && continue
                git remote add "$r_name" "$r_url"
                ;;
            "Remove Remote")
                local remotes=$(git remote)
                if [[ -n "$remotes" ]]; then
                    local r_rm=$(echo "$remotes" | gum choose --header="Select remote to remove")
                    [[ -n "$r_rm" ]] && git remote remove "$r_rm"
                else
                    echo -e "${RED}No remotes found.${RESET}"; sleep 1
                fi
                ;;
            "Change Remote URL")
                local remotes=$(git remote)
                if [[ -n "$remotes" ]]; then
                    local r_ch=$(echo "$remotes" | gum choose --header="Select remote to modify")
                    if [[ -n "$r_ch" ]]; then
                        local old_url=$(git remote get-url "$r_ch")
                        local new_url=$(gum input --prompt="New URL for $r_ch: " --value="$old_url")
                        [[ -n "$new_url" && "$new_url" != "$old_url" ]] && git remote set-url "$r_ch" "$new_url"
                    fi
                else
                    echo -e "${RED}No remotes found.${RESET}"; sleep 1
                fi
                ;;
            "Back")
                break
                ;;
        esac
    done
}

manage_repo() {
    local repo_path="$1"
    cd "$repo_path" || { echo "Cannot access $repo_path"; sleep 2; return; }

    while true; do
        clear
        title
        echo -e "${BLUE}Current Repository:${RESET} ${WHITE}$repo_path${RESET}\n"

        local choice
        choice=$(gum choose \
            --cursor="> " \
            "Status" \
            "Log" \
            "Commit" \
            "Pull" \
            "Push" \
            "Immediate Push" \
            "Mirrors" \
            "Revert" \
            "Editor" \
            "Explorer" \
            "Shell" \
            "SSH" \
            "Back" \
            "Quit")

        case "$choice" in
            "Status")
                clear
                title
                echo -e "${YELLOW}Git Status:${RESET}"
                git status
                echo ""
                gum confirm "Press Enter to continue" || true
                ;;
            "Log")
                clear
                title
                echo -e "${YELLOW}Repository Log (Press 'q' to exit):${RESET}\n"
                git log --color=always --graph --pretty=format:"%C(yellow)%h%Creset%C(magenta)%d%Creset | %s %C(green)(%cr) %C(cyan)[%an]%Creset" | gum pager
                ;;
            "Commit")
                clear
                title
                echo -e "${YELLOW}Git Status:${RESET}"
                git status -s
                echo ""
                local msg
                msg=$(gum input --prompt="Commit Message: " --width=70)
                if [[ -n "$msg" ]]; then
                    git add .
                    git commit -m "$msg"
                    echo -e "\n${GREEN}Committed successfully!${RESET}"
                else
                    echo -e "\n${RED}Commit aborted (empty message).${RESET}"
                fi
                gum confirm "Press Enter to continue" || true
                ;;
            "Pull")
                clear
                title
                echo -e "${BLUE}Pulling changes...${RESET}\n"
                git pull
                echo ""
                gum confirm "Press Enter to continue" || true
                ;;
            "Push")
                clear
                title
                echo -e "${BLUE}Pushing changes...${RESET}\n"
                git push
                echo ""
                gum confirm "Press Enter to continue" || true
                ;;
            "Immediate Push")
                clear
                title
                echo -e "${YELLOW}Immediate Push (Push to ALL Mirrors)${RESET}\n"
                local remotes=$(git remote)

                if [[ -z "$remotes" ]]; then
                    echo -e "${RED}No remotes found. Please add a mirror first.${RESET}"
                else
                    git status -s
                    echo ""
                    local msg
                    msg=$(gum input --prompt="Commit Message: " --width=70)
                    if [[ -n "$msg" ]]; then
                        git add .
                        git commit -m "$msg"
                        echo ""

                        local current_branch
                        current_branch=$(git branch --show-current)
                        [[ -z "$current_branch" ]] && current_branch="HEAD"

                        for r in $remotes; do
                            echo -e "${BLUE}Pushing to remote: ${WHITE}$r${RESET}"
                            git push "$r" "$current_branch"
                        done
                        echo -e "\n${GREEN}Immediate Push completed!${RESET}"
                    else
                        echo -e "\n${RED}Aborted (empty message).${RESET}"
                    fi
                fi
                gum confirm "Press Enter to continue" || true
                ;;
            "Mirrors")
                manage_mirrors
                ;;
            "Revert")
                clear
                title
                echo -e "${YELLOW}Select a commit to Revert:${RESET}\n"

                if ! git rev-parse HEAD >/dev/null 2>&1; then
                    echo -e "${RED}No commits found in this repository.${RESET}"
                else
                    local selected_commit
                    selected_commit=$(git log --color=always --pretty=format:"%C(yellow)%h%Creset | %s %C(green)(%cr) %C(cyan)[%an]%Creset" -n 50 | \
                        fzf --ansi --prompt="Revert> " \
                            --header="Select commit to revert (Enter to confirm, Esc to cancel)" \
                            --color="bg+:#3c3836,bg:#282828,spinner:#fb4934,hl:#8ec07c" \
                            --color="fg:#ebdbb2,header:#8ec07c,info:#fabd2f,pointer:#fb4934" \
                            --color="marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#8ec07c")

                    if [[ -n "$selected_commit" ]]; then
                        local commit_hash
                        commit_hash=$(echo "$selected_commit" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')

                        echo -e "\n${YELLOW}Selected commit: $commit_hash${RESET}"
                        if gum confirm "Revert changes made by $commit_hash?"; then
                            if git revert "$commit_hash" --no-edit; then
                                echo -e "\n${GREEN}Reverted successfully (New commit generated)!${RESET}"
                            else
                                echo -e "\n${RED}Revert failed (conflict?). You may need to resolve it manually.${RESET}"
                            fi
                        else
                            echo -e "\n${YELLOW}Revert canceled.${RESET}"
                        fi
                    else
                        echo -e "\n${YELLOW}No commit selected.${RESET}"
                    fi
                fi
                gum confirm "Press Enter to continue" || true
                ;;
            "Editor")
                nvim .
                ;;
            "Explorer")
                if command -v yazi &>/dev/null; then
                    yazi .
                else
                    echo -e "${RED}Error: yazi is not installed.${RESET}"
                    sleep 2
                fi
                ;;
            "Shell")
                clear
                title
                echo -e "${YELLOW}Select Shell for $repo_path:${RESET}\n"
                local sh_choice
                sh_choice=$(gum choose --cursor="> " "zsh" "fish" "bash" "Back")

                if [[ "$sh_choice" != "Back" && -n "$sh_choice" ]]; then
                    if command -v "$sh_choice" &>/dev/null; then
                        echo -e "\n${GREEN}Entering $sh_choice. Type 'exit' or press Ctrl+D to return to GitCooker.${RESET}\n"
                        "$sh_choice"
                    else
                        echo -e "\n${RED}Error: $sh_choice is not installed.${RESET}"
                        sleep 2
                    fi
                fi
                ;;
            "SSH")
                mkdir -p "$REAL_HOME/.ssh"
                nvim "$REAL_HOME/.ssh/config"
                ;;
            "Back")
                return 0
                ;;
            "Quit")
                clear
                exit 0
                ;;
        esac
    done
}

select_repo() {
    while true; do
        if [[ ! -f "$CACHE_FILE" ]]; then
            update_cache
        fi

        clear

        # Select Repository with FZF
        local selected_repo
        selected_repo=$(cat "$CACHE_FILE" | fzf \
            --prompt="Select Repo> " \
            --header="GitCooker - Select a Repository (Press Ctrl-R to refresh cache, Esc to return to Main Menu)" \
            --header-first \
            --bind "ctrl-r:execute(\"$SCRIPT_PATH\" _refresh_cache)+reload(cat \"$CACHE_FILE\")" \
            --color="bg+:#3c3836,bg:#282828,spinner:#fb4934,hl:#8ec07c" \
            --color="fg:#ebdbb2,header:#8ec07c,info:#fabd2f,pointer:#fb4934" \
            --color="marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#8ec07c")

        if [[ -z "$selected_repo" ]]; then
            return 0
        fi

        if [[ -d "$selected_repo" ]]; then
            manage_repo "$selected_repo"
        else
            echo -e "${RED}Directory does not exist: $selected_repo${RESET}"
            echo -e "${YELLOW}Please refresh the cache (Ctrl-R).${RESET}"
            sleep 2
        fi
    done
}

main_menu() {
    while true; do
        clear
        title
        echo -e "${YELLOW}Main Menu${RESET} - Current Dir: ${WHITE}$(pwd)${RESET}\n"

        local main_choice
        main_choice=$(gum choose \
            --cursor="> " \
            "Select" \
            "Clone" \
            "Editor" \
            "Explorer" \
            "Shell" \
            "SSH" \
            "Quit")

        case "$main_choice" in
            "Select")
                select_repo
                ;;
            "Clone")
                clear
                title
                echo -e "${YELLOW}Clone Repository${RESET}\n"

                local link dest
                link=$(gum input --prompt="Repository URL (e.g. github.com/user/repo): " --width=70)
                [[ -z "$link" ]] && continue

                dest=$(gum input --prompt="Destination Path (e.g. ~/projects/repo): " --width=70)
                [[ -z "$dest" ]] && continue

                # Expand tilde if present
                dest="${dest/#\~/$REAL_HOME}"

                echo ""
                clone "$link" "$dest"

                # Automatically refresh cache if clone is successful
                if [[ -d "$dest" ]]; then
                    echo -e "\n${GREEN}Updating cache with new repository...${RESET}"
                    update_cache
                fi

                gum confirm "Press Enter to continue" || true
                ;;
            "Editor")
                nvim .
                ;;
            "Explorer")
                if command -v yazi &>/dev/null; then
                    yazi .
                else
                    echo -e "${RED}Error: yazi is not installed.${RESET}"
                    sleep 2
                fi
                ;;
            "Shell")
                clear
                title
                echo -e "${YELLOW}Select Shell for $(pwd):${RESET}\n"
                local sh_choice
                sh_choice=$(gum choose --cursor="> " "zsh" "fish" "bash" "Back")

                if [[ "$sh_choice" != "Back" && -n "$sh_choice" ]]; then
                    if command -v "$sh_choice" &>/dev/null; then
                        echo -e "\n${GREEN}Entering $sh_choice. Type 'exit' or press Ctrl+D to return to GitCooker.${RESET}\n"
                        "$sh_choice"
                    else
                        echo -e "\n${RED}Error: $sh_choice is not installed.${RESET}"
                        sleep 2
                    fi
                fi
                ;;
            "SSH")
                mkdir -p "$REAL_HOME/.ssh"
                nvim "$REAL_HOME/.ssh/config"
                ;;
            "Quit")
                clear
                exit 0
                ;;
        esac
    done
}

main() {
    # Dependency check
    for cmd in git fd fzf gum nvim; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${RED}Error: '$cmd' is not installed or not in PATH.${RESET}"
            exit 1
        fi
    done

    # Enter Main Menu Loop
    main_menu
}

# ==============================================================================
#  Execution Point
# ==============================================================================
if [[ $# -gt 0 ]]; then
    # Parse inline arguments to reuse your standalone functions seamlessly
    case "$1" in
        _refresh_cache) update_cache; exit 0 ;;
        repo)           shift; repo "$@" ;;
        clone)          shift; clone "$@" ;;
        remove)         shift; remove "$@" ;;
        upload)         shift; upload "$@" ;;
        *)              repo "$@" ;;
    esac
    exit $?
fi

main