# _[MolniOS](https://codeberg.org/al1h3n/molnios-install)_ sway notification center keybinds:
`Up/Down` - Navigate notifications.<br>
`Home` - Navigate to the latest notification.<br>
`End` - Navigate to the oldest notification.<br>
`Escape/Caps_Lock` - Close notification panel.<br>
`Return` - Execute default action or close notification if none.<br>
`Delete/BackSpace` - Close notification.<br>
`Shift+C` - Close all notifications.<br>
`Shift+D` - Toggle Do Not Disturb.<br>
`1-9` - Execute alternative actions.<br>
`LMB/actions` - Activate notification action.<br>
`MMB/RMB notification` - Close notification.<br>

### Important note
If you will use `tlp` modes for perfomance/power saving you will need to disable password on `tlp`.
On imperative distro:
```
sudo visudo -f /etc/sudoers.d/tlp

# Set your username.
your_username ALL=(ALL) NOPASSWD: /usr/sbin/tlp
```