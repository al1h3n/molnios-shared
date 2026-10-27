-- Queue loading from the NixOS Home Manager profile, as with HyprGlass.
-- Hyprland reloads after loading plugins; the API is absent on the first pass.
hl.plugin.load("/etc/profiles/per-user/" .. (os.getenv("USER") or "") .. "/lib/hypr3d.so")

if hl.plugin.hypr3d then
    local hypr3d = hl.plugin.hypr3d
    local home = os.getenv("HOME")
    local library = home .. "/Downloads/Hypr3D_Scenes/"
    local scenes = dofile(library .. "scenes.lua")
    local selected = "cedar"
    local state = io.open(home .. "/.config/hypr/hypr3d-scene")
    if state then
        selected = state:read("*l") or selected
        state:close()
    end
    local scene = scenes[1]
    for _, candidate in ipairs(scenes) do
        if candidate.id == selected then scene = candidate end
    end
    _G.hypr3d_scene = scene.id
    local controller = (_G.conf_lua or (home .. "/.local/share/molnios/config/hyprland/")) .. "hypr3d-scenes.py"
    local function select_scene(action)
        hl.exec_cmd("python3 " .. string.format("%q", controller) .. " " .. action)
    end
    local controls = {
        prev = function() select_scene("prev") end,
        next = function() select_scene("next") end,
        reset = function() select_scene("reset") end,
    }
    _G.hypr3d_controls = controls
    hl.bind("SUPER + F12", hypr3d.toggle)
    hl.bind("SUPER + F6", controls.prev)
    hl.bind("SUPER + F7", controls.next)
    hl.bind("SUPER + F8", controls.reset)
    local flying = scene.flying
    local inspecting = false
    local function apply_movement()
        hypr3d.config({ player = {
            flying = inspecting or flying,
            collision = not inspecting,
        } })
    end
    controls.fly = function()
        flying = not flying
        apply_movement()
    end
    controls.inspect = function()
        inspecting = not inspecting
        apply_movement()
    end
    hl.bind("SUPER + F10", controls.fly)
    hl.bind("SUPER + F11", controls.inspect)

    hypr3d.config({
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
            move_speed = 3.5,
            spawn = scene.spawn,
            flying = scene.flying,
            collision = true,
            walk_bob = true,         -- Head bobbing for immersion
            mesh = {
                path = library .. "Block_Player.glb",
                transform = { position = { 0, 0, 0 }, rotation = { 0, 0, 0 }, scale = { 1, 1, 1 } },
                center = "origin",
                flat = true,
            },
            animations = {
                idle = { source = "Idle" }, walk = { source = "Walk" },
                run = { source = "Run" }, jump = { source = "Jump" },
            },
        },
        scene = {
            house = {
                mesh = {
                    path = scene.path,
                    transform = {
                        position = scene.position,
                        rotation = { 0, 0, 0 },
                        scale = scene.scale,
                    },
                    emissive_scale = 1.0,
                    flat = true, -- Daylight is baked into the embedded colour textures.
                    center = "origin",
                },
                collision = true,    -- Solid collision with walls/floor
                static = true,       -- Static map architecture
                physics = false,     -- Dynamic rigid-body simulation not needed for the map itself
            },
        },
    })
end
