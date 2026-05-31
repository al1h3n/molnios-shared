local act = wezterm.action

config.keys = {
  -- Ctrl+Shift+G → vertical split (side by side)
  {
    key = 'G',
    mods = 'CTRL|SHIFT',
    action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  -- Ctrl+Shift+B → horizontal split (top and bottom)
  {
    key = 'B',
    mods = 'CTRL|SHIFT',
    action = act.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  -- Ctrl+Shift+W → close current pane (with confirmation prompt)
  {
    key = 'W',
    mods = 'CTRL|SHIFT',
    action = act.CloseCurrentPane { confirm = false },
  },
}