# Shared files for [MolniOS](https://codeberg.org/al1h3n/molnios-install) project.
## (dotfiles, configurations, scripts)

### How to download this repo.
Type (use any of these mirrors):
```
git clone --depth=1 --filter=blob:none https://github.com/al1h3n/molnios-shared
git clone --depth=1 --filter=blob:none https://gitlab.com/al1h3n/molnios-shared
git clone --depth=1 --filter=blob:none https://codeberg.org/al1h3n/molnios-shared
```

### FAQ

#### My PC is lagging
- Hyprland: disable effects in following files.
```
animations.lua
rules.lua
visual.lua
```
- Niri: disable effects in following files.
```
animations.kdl
rules.kdl
visual.kdl
```

#### What if I have AMD GPU?
Remove NVIDIA parameters from env.lua (hyprland) and env.kdl (niri).

#### How to clear my clipboard history?
`rm -f ~/.cache/cliphist/db`