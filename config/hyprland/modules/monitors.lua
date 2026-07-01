-- Monitors
hl.monitor({
    output   = "DP-1",
    mode     = "highres@highrr",
    position = "0x0",
    scale    = "1.25"
})
hl.config({
    xwayland = {
        force_zero_scaling = true
    },
})