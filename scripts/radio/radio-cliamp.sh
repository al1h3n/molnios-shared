# Sourced by yt-x with -x after its built-in player functions are defined.
__player_mpv(){
    cliamp --vol "${RADIO_VOLUME:--13}" "$1"
}