-- Environment variables.
local envs = {
    -- Nvidia.
    LIBVA_DRIVER_NAME = "nvidia",
    __GLX_VENDOR_LIBRARY_NAME = "nvidia",
    NVD_BACKEND = "direct",
    __GL_GSYNC_ALLOWED = 1,
    -- Perfomance.
    GDK_BACKEND = "wayland,x11,*", -- Use Wayland if available, if not X11.
    -- Electron.
    ELECTRON_OZONE_PLATFORM_HINT = "auto",
    -- Qt.
    QT_QPA_PLATFORMTHEME = "qt6ct",
    QT_QPA_PLATFORM = "wayland", -- Use Wayland if available, if not X11.
    -- Cursor.
    HYPRCURSOR_SIZE = "29",
    HYPRCURSOR_THEME = CURSOR,
    XCURSOR_SIZE = "29",
    XCURSOR_THEME = CURSOR,
}

for x, y in pairs(envs) do
    hl.env(x, y)
end