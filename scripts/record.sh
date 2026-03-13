# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - ko-fi.com/al1h3n
# Molniux Recorder v1 - First release.
# Part of the MolniOS project.

# n - number, s - string, d - dir, x - none.
# -R: Set resolution [W:H]
# -r: Set FPS [n]
# -c: Set Codec [s]
# -g: Geometry (from slurp) [s]
# -f: Output file [d]
# -a: Audio (if flag was set) [x]
# -o: Use OBS Studio instead of wf-recorder [x]

# ==============================================================================

# 0. Pre definitions.
# Requirements: ffmpeg, slurp (region selection), wf-recorder (actual recorder), nvidia-smi (if you need NVENC encoder), OBS (in -o flag).

# 0.1 Default variables.
RESOLUTION=1920:1080
FPS=30
AUDIO_FLAG=
FILE=~/Videos/recording_$(date +%Y-%m-%d_%H:%M:%S).mp4
RECORDER="wf-recorder"

# 0.2. Functions.
exists(){
	command -v $1&>/dev/null
}

# 1. Parse command line arguments (e.g., -a for audio).
while getopts "R:r:c:g:f:ao" opt;do
  case $opt in
    R)
      RESOLUTION=$OPTARG
      ;;
  	r)
      FPS=$OPTARG
      ;;
    c)
      CODEC_USER=$OPTARG
      ;;
    g)
      GEOMETRY=$OPTARG
      ;;
    f)
      FILE=$OPTARG
      ;;
    a)
      AUDIO_FLAG="-a" # Enables default audio source. To select a specific device, wf-recorder allows -a <device>
      ;;
    o)
      RECORDER="obs"
      ;;
    \?)
      echo "Invalid option: -$OPTARG">&2
      exit 1
      ;;
  esac
done

# 1.1. Error handler.
if ! [[ $RESOLUTION =~ ^[0-9]+:[0-9]+$ ]];then
    notify-send -u critical "Recorder Error" "Invalid resolution format: $RESOLUTION. Please use WIDTH:HEIGHT (e.g. 1920:1080)"
    exit 1
fi

# 2. Check if recording is already running.

# 2.1. wf-recorder case.
if pgrep -x wf-recorder > /dev/null;then
    pkill -INT -x wf-recorder
    notify-send -t 3000 "Recording stopped" "File was saved via wf-recorder."
    exit 0
fi

# 2.2. OBS case.
if pgrep -x obs > /dev/null;then
    # Send SIGINT to OBS to stop recording gracefully and save the file.
    pkill -INT -x obs
    notify-send -t 3000 "OBS Recording stopped" "File saved via OBS."
    exit 0
fi

# 3. Launch OBS via -o flag.
if [ $RECORDER = "obs" ];then
    # OBS uses settings defined inside the OBS GUI.
    if ! exists obs; then
        notify-send -u critical -t 3000 "Error" "OBS Studio is not installed."
        exit 1
    fi
    nohup obs --startrecording --minimize-to-tray >/dev/null 2>&1 &
    notify-send -u critical "OBS Recording started" "Using OBS internal settings."
    exit 0
fi

# 3. Detect NVIDIA GPU to use NVENC codec.
# Checks if nvidia-smi command exists and returns success.
if [ -n "$CODEC_USER" ];then
    CODEC=$CODEC_USER
else
    if exists nvidia-smi && nvidia-smi &>/dev/null;then
        CODEC="hevc_nvenc" 
    else
        CODEC="libx265"
    fi
fi

# 4. Select region.
if [ -z $GEOMETRY ]; then
    # If user didn't provide -g, use slurp to select interactively
    GEOMETRY=$(slurp -b 000000CC -s FFFFFF00 -c 00FF00 -w 1)
    
    # If user pressed Esc, slurp returns empty string. We exit.
    if [ -z $GEOMETRY ];then
        exit 0
    fi
fi

# 5. Start recording.
wf-recorder -c $CODEC -F scale=$RESOLUTION -r $FPS $AUDIO_FLAG -g $GEOMETRY -f $FILE &

# Notify user.
notify-send -u critical "Recording started" "Codec: $CODEC, Audio: $([ -n $AUDIO_FLAG ]&&echo "On"||echo "Off"), Resolution: $RESOLUTION@$FPS, Will be saved to $FILE"
