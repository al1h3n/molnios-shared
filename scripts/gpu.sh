# ==========================================================
# GPU usage script v1
# Changed: first release.
# Part of the MolniOS project.
# ==========================================================

get_intel_usage() {
    local card=$1
    # Try different paths for current and max frequency.
    if [ -f "$card/gt_act_freq_mhz" ];then
        curr=$(cat "$card/gt_act_freq_mhz")
        max=$(cat "$card/gt_max_freq_mhz")
    elif [ -f "$card/gt/gt0/act_freq_mhz" ];then
        curr=$(cat "$card/gt/gt0/act_freq_mhz")
        max=$(cat "$card/gt/gt0/rp0_freq_mhz")
    elif [ -f "$card/device/cur_freq" ];then
        curr=$(cat "$card/device/cur_freq")
        max=$(cat "$card/device/max_freq")
    fi

    # Calculate percentage if values exist
    if [[ -n "$curr" && -n "$max" && "$max" -gt 0 ]]; then
        echo $((100*curr/max))%
        return 0
    fi
    return 1
}

# 1. Check for Nvidia.
if command -v nvidia-smi&>/dev/null;then
    usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n 1)
    echo ${usage}%

# 2. Check for AMD (looking for gpu_busy_percent in standard paths)
elif [ -f /sys/class/drm/card0/device/gpu_busy_percent ]; then
    usage=$(cat /sys/class/drm/card0/device/gpu_busy_percent)
    echo ${usage}%
elif [ -f /sys/class/drm/card1/device/gpu_busy_percent ]; then
    usage=$(cat /sys/class/drm/card1/device/gpu_busy_percent)
    echo ${usage}%

# 3. Check for Intel (Arc or iGPU) - Try card1 (often dGPU) then card0.
elif [ -d /sys/class/drm/card1 ] && get_intel_usage "/sys/class/drm/card1";then
    : # Output handled by function.
elif [ -d /sys/class/drm/card0 ] && get_intel_usage "/sys/class/drm/card0";then
    : # Output handled by function.

else
    echo "No GPU found"
fi
