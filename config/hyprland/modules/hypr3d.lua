-- 1. Load the Hypr3D shared library built by NixOS
-- If installed via nix profile / environment:
hl.exec_cmd("hyprctl plugin load " .. os.getenv("HOME") .. "/.nix-profile/lib/libhypr3d.so")

-- 2. Configure Keybinds
hl.bind("SUPER + F12", hl.plugin.hypr3d.toggle)

-- 3. Hypr3D Environment & Backrooms Setup
if hl.plugin.hypr3d then
    hl.plugin.hypr3d.config({
        world = {
            grid = false, -- Disable the default floating grid platform
            panorama = "", -- Optional: path to an equirectangular skybox if there's an open ceiling
        },
        windows = {
            window_scale = 0.45,     -- Scale factor for windows in 3D meters
            spawn_distance = 2.5,    -- Distance (meters) from camera where new windows spawn
        },
        player = {
            look_sensitivity = 0.0025,
            look_inertia = 0.03,
            move_inertia = 0.05,
            move_speed = 3.5,        -- Walking speed in the backrooms
            spawn = { x = 0, y = 1.0, z = 0 }, -- Starting coordinates above the floor
            flying = false,          -- Set to false so you remain grounded with gravity/collision
            walk_bob = true,         -- Head bobbing for immersion
        },
        scene = {
            house = {
                path = os.getenv("HOME") .. "/Downloads/a_modern_house_design.glb",
                transform = {
                    position = { 0, 0, 0 },
                    rotation = { 0, 0, 0 },
                    scale = { 1, 1, 1 },
                },
                collision = true,    -- Solid collision with walls/floor
                static = true,       -- Static map architecture
                physics = false,     -- Dynamic rigid-body simulation not needed for the map itself
                emissive_scale = 1.2, -- Adjust brightness of the fluorescent lights
                flat = true,
            },
        },
    })
end