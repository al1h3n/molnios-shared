if command -v spotify >/dev/null; then
    exec spotify
elif command -v spotify-launcher >/dev/null; then
    exec spotify-launcher
elif command -v flatpak >/dev/null; then
    exec flatpak run com.spotify.Client
else
    exec spotify-launcher
fi