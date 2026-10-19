#!/bin/bash
# Copy this machine's live rice into ./home so install.sh reproduces it.
# Run it again whenever you've tweaked something you want to keep.
set -euo pipefail
repo=$(cd "$(dirname "$0")" && pwd)
dst="$repo/home"

configs=(hypr quickshell waybar fuzzel mako kitty alacritty)
mkdir -p "$dst/.config" "$dst/.config/uwsm" "$dst/.config/autostart" "$dst/Pictures/Wallpapers"

for c in "${configs[@]}"; do
  rsync -a --delete --exclude '__pycache__' "$HOME/.config/$c/" "$dst/.config/$c/"
done
cp -a "$HOME/.config/uwsm/env-hyprland" "$dst/.config/uwsm/"
cp -a "$HOME/.config/xdg-terminals.list" "$dst/.config/"
mkdir -p "$dst/.config/systemd/user" && cp -a "$HOME/.config/systemd/user/quickshell.service" "$dst/.config/systemd/user/"
# Autostart entries we hide in Hyprland (duplicate tray icons, KDE's video bridge window)
for f in blueman.desktop nm-applet.desktop org.kde.xwaylandvideobridge.desktop; do
  [ -f "$HOME/.config/autostart/$f" ] && cp -a "$HOME/.config/autostart/$f" "$dst/.config/autostart/"
done
mkdir -p "$dst/.local/bin" && cp -a "$HOME/.local/bin/add-to-search" "$HOME/.local/bin/reboot-macos" "$dst/.local/bin/"
rsync -a "$HOME/Pictures/Wallpapers/sequoia-dark.jpg" "$HOME/Pictures/Wallpapers/sequoia-light.jpg" "$dst/Pictures/Wallpapers/"
ln -sfn sequoia-dark.jpg "$dst/Pictures/Wallpapers/current.jpg"

# Machine-specific bits that shouldn't travel
sed -i 's|^-- │  Old Omarchy setup:.*│$|-- │  Installed with macrice (see ~/macrice/README.md)       │|' "$dst/.config/hypr/hyprland.lua"
cat > "$dst/.config/uwsm/env" <<'ENV'
# Environment for the uwsm-managed Hyprland session
export PATH=$HOME/.local/bin:$PATH
export TERMINAL=kitty
ENV

# Your saved preferences (dock, trackpad, trail, appearance, charge limit…).
# Quickshell keeps them in a folder named after md5(path of shell.qml).
id=$(printf '%s' "$HOME/.config/quickshell/shell.qml" | md5sum | cut -d' ' -f1)
state="$HOME/.local/state/quickshell/by-shell/$id"
rm -rf "$repo/state" && mkdir -p "$repo/state"
[ -d "$state" ] && cp -a "$state"/. "$repo/state/" 2>/dev/null || true

echo "Synced into $dst (+ preferences into $repo/state)"
