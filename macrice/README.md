# macrice

A macOS-style Hyprland desktop for **Fedora Asahi Remix** on Apple Silicon Macs:
a menu bar with real dropdowns (Wi-Fi, Bluetooth, Sound, Battery, Control Center),
an auto-hiding dock you can drag to rearrange, Spotlight-style search, Mission Control,
System Settings, Light/Dark mode, and ⌘-style shortcuts. Built with Quickshell.

Made on a MacBook Pro 14" (M2 Max) running Fedora Asahi Remix 44.

## Install

```bash
cd ~/macrice        # or wherever you copied/cloned this folder
./install.sh
```

Then log out and choose **Hyprland (uwsm-managed)** on the login screen.

The installer:

1. installs the packages in `packages.txt` (Hyprland comes from the `sdegler/hyprland` COPR),
2. installs the JetBrainsMono Nerd Font (for icons),
3. moves any configs it would replace to `~/macrice-backup-<date>/`,
4. copies `home/` into your home folder,
5. on MacBooks with a notch, offers to use the space beside it for the menu bar,
6. restores the saved preferences in `state/` (dock, trackpad, cursor trail, appearance, charge limit),
7. allows the battery menu to set a charge limit (a udev rule, `system/`),
8. themes GTK and KDE apps and the cursor.

Options: `--skip-packages` (configs only), `--yes` (no questions).

KDE Plasma stays installed and selectable on the login screen as a fallback.

## Keep it up to date

After changing things on your machine, run:

```bash
~/macrice/sync-from-system.sh
```

That copies your live configs and preferences back into this folder, so `install.sh`
reproduces exactly what you have now.

## Where things live

| What | Where |
|---|---|
| Hyprland (keys, rules, look) | `~/.config/hypr/` (Lua config, Hyprland 0.55+) · shortcuts in `bindings.lua` |
| Menu bar, dock, dropdowns, Settings | `~/.config/quickshell/` · colours in `common/Theme.qml` |
| Helper scripts | `~/.config/hypr/scripts/` |
| Terminal | `~/.config/kitty/` |
| Wallpapers | `~/Pictures/Wallpapers/` (`sequoia-dark.jpg` / `sequoia-light.jpg`) |

## Handy shortcuts

`⌘ /` shows them all. A few: `⌘Space` search · `⌘Return` terminal · `⌘Q` close ·
`⌘⇧3/4/5` screenshots · `⌃⌘↑` or three-finger swipe up for Mission Control ·
`⌥⌘Space` Control Center · `⌘Esc` Apple menu.

## Undo

Log into KDE (or a TTY), then move the folders back from `~/macrice-backup-<date>/`.
To drop the charge-limit permission: `sudo rm /etc/udev/rules.d/94-macsmc-battery-user.rules`.
