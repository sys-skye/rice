#!/bin/bash
# macrice installer: a macOS-style Hyprland desktop for Fedora Asahi Remix (Apple Silicon Macs).
#
#   ./install.sh                 install everything
#   ./install.sh --skip-packages only copy configs (packages already installed)
#   ./install.sh --yes           don't ask questions (keeps the notch setting as it is)
#
# Anything it replaces is moved to ~/macrice-backup-<date>/ first.
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)
skip_packages=0 assume_yes=0
for a in "$@"; do
  case $a in
  --skip-packages) skip_packages=1 ;;
  --yes | -y) assume_yes=1 ;;
  -h | --help) sed -n '2,8p' "$0"; exit 0 ;;
  *) echo "unknown option: $a" >&2; exit 1 ;;
  esac
done

bold=$'\e[1m' dim=$'\e[2m' blue=$'\e[34m' yellow=$'\e[33m' red=$'\e[31m' reset=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$blue$bold" "$*" "$reset"; }
note() { printf '%s    %s%s\n' "$dim" "$*" "$reset"; }
warn() { printf '%s    ! %s%s\n' "$yellow" "$*" "$reset"; }
ask() {  # ask "question" → 0 for yes
  ((assume_yes)) && return 1
  local r; read -rp "    $1 [y/N] " r; [[ $r == [yY]* ]]
}

# ── Checks ──────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] || { echo "${red}Run this as your normal user, not root (it uses sudo when needed).${reset}"; exit 1; }
. /etc/os-release
[[ ${ID:-} == fedora* || " ${ID_LIKE:-} " == *" fedora "* ]] || { echo "${red}This installer is for Fedora (Asahi Remix). Found: ${PRETTY_NAME:-unknown}.${reset}"; exit 1; }
model=$(tr -d '\0' </proc/device-tree/model 2>/dev/null || echo "unknown")
is_mac=0; grep -q "apple," /proc/device-tree/compatible 2>/dev/null && is_mac=1

printf '%smacrice%s · macOS-style Hyprland for Fedora Asahi\n' "$bold" "$reset"
note "System: $PRETTY_NAME on $(uname -m) · $model"
((is_mac)) || warn "Not an Apple Silicon Mac: the rice works, but battery/notch/backlight extras won't."

# ── 1. Packages ─────────────────────────────────────────────────────
if ((skip_packages)); then
  step "Skipping packages (--skip-packages)"
else
  step "Installing packages (sudo)"
  sudo dnf copr enable -y sdegler/hyprland
  mapfile -t pkgs < <(sed 's/#.*//' "$repo/packages.txt" | tr ' ' '\n' | grep -v '^$')
  sudo dnf install -y --skip-unavailable "${pkgs[@]}"
fi
# The config is Lua (hyprland.lua), which needs Hyprland 0.55 or newer
hl_version=$(Hyprland --version-json 2>/dev/null | sed -n 's/.*"tag": *"v\{0,1\}\([0-9.]*\)".*/\1/p' | head -1)
if [[ -n $hl_version ]] && [[ $(printf '%s\n' 0.55 "$hl_version" | sort -V | head -1) != 0.55 ]]; then
  warn "Hyprland $hl_version is too old for this config (needs 0.55+, which reads hyprland.lua)"
fi

# ── 2. Nerd Font (icons in the bar, dock, terminal) ────────────────
step "JetBrainsMono Nerd Font"
if fc-list | grep -q "JetBrainsMono Nerd Font"; then
  note "already installed"
else
  fontdir=~/.local/share/fonts/JetBrainsMonoNerd
  mkdir -p "$fontdir"
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/font.tar.xz" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
  tar -xJf "$tmp/font.tar.xz" -C "$fontdir"
  rm -rf "$tmp"
  fc-cache -f "$fontdir" >/dev/null
  note "installed to $fontdir"
fi

# ── 3. Back up what we're about to replace ─────────────────────────
step "Backing up existing configs"
backup=~/macrice-backup-$(date +%Y%m%d-%H%M%S)
moved=0
rels=()
for d in "$repo"/home/.config/*; do                      # whole app folders (hypr, quickshell, kitty…)
  case $(basename "$d") in uwsm | autostart) ;; *) rels+=(".config/$(basename "$d")") ;; esac
done
for f in "$repo"/home/.config/uwsm/* "$repo"/home/.config/autostart/* "$repo"/home/Pictures/Wallpapers/*; do
  rels+=("${f#"$repo/home/"}")                            # single files inside shared folders
done
for rel in "${rels[@]}"; do
  if [[ -e $HOME/$rel || -L $HOME/$rel ]]; then
    mkdir -p "$backup/$(dirname "$rel")"
    mv "$HOME/$rel" "$backup/$rel"
    moved=1
  fi
done
((moved)) && note "saved to $backup" || note "nothing to back up"

# ── 4. Copy the rice ───────────────────────────────────────────────
step "Copying configs, scripts and wallpapers"
rsync -a "$repo/home/" "$HOME/"
chmod +x ~/.config/hypr/scripts/* ~/.config/quickshell/assets/*.py 2>/dev/null || true
note "~/.config/{hypr,quickshell,kitty,alacritty,fuzzel,mako,waybar}, ~/Pictures/Wallpapers"

# ── 5. Notch ───────────────────────────────────────────────────────
step "Menu bar and the notch"
theme=~/.config/quickshell/common/Theme.qml
if grep -q "appledrm.show_notch=1" /proc/cmdline; then
  note "notch area is in use: the bar keeps the middle free for it"
elif [[ $model =~ MacBook\ Pro\ \((14|16)-inch || $model =~ MacBook\ Air\ \((13-inch,\ M[2-9]|15-inch) ]]; then
  note "This Mac has a notch. Asahi can give you the screen area beside it for the menu bar (like macOS)."
  if ask "Use the area beside the notch? (takes effect after a reboot)"; then
    sudo grubby --update-kernel=ALL --args="appledrm.show_notch=1"
    note "enabled; reboot to see it"
    reboot_needed=1
  else
    sed -i 's/readonly property bool hasNotch: true/readonly property bool hasNotch: false/' "$theme"
    note "keeping the notch hidden: the bar uses the full width"
  fi
else
  sed -i 's/readonly property bool hasNotch: true/readonly property bool hasNotch: false/' "$theme"
  note "no notch: the bar uses the full width"
fi

# ── 6. Your saved preferences (dock, trackpad, trail, appearance…) ──
step "Preferences"
id=$(printf '%s' "$HOME/.config/quickshell/shell.qml" | md5sum | cut -d' ' -f1)
state=~/.local/state/quickshell/by-shell/$id
mkdir -p "$state"
if compgen -G "$repo/state/*" >/dev/null; then
  cp -n "$repo/state/"* "$state/" 2>/dev/null || true
  note "restored into $state (existing ones kept)"
else
  note "none saved: using defaults"
fi

# ── 7. Battery charge limit permission (Asahi) ─────────────────────
step "Battery charge limit"
if [[ -d /sys/class/power_supply/macsmc-battery ]]; then
  sudo install -m644 "$repo/system/94-macsmc-battery-user.rules" /etc/udev/rules.d/
  sudo udevadm control --reload
  sudo udevadm trigger --action=change --subsystem-match=power_supply --sysname-match=macsmc-battery
  note "the battery menu can now set a charge limit"
else
  note "no Apple battery found: skipped"
fi

# ── 8. Theme: GTK, KDE/Qt apps, cursor, default apps ───────────────
step "Theming apps"
~/.config/hypr/scripts/apply-gtk-theme || true
cursor_theme=$(sed -n 's/^hl.env("XCURSOR_THEME", "\(.*\)")$/\1/p' ~/.config/hypr/cursor.lua)
cursor_size=$(sed -n 's/^hl.env("XCURSOR_SIZE", "\(.*\)")$/\1/p' ~/.config/hypr/cursor.lua)
gsettings set org.gnome.desktop.interface cursor-theme "${cursor_theme:-Adwaita}"
gsettings set org.gnome.desktop.interface cursor-size "${cursor_size:-24}"
~/.config/hypr/scripts/appearance dark >/dev/null 2>&1 || true
xdg-mime default org.gnome.Nautilus.desktop inode/directory 2>/dev/null || true
note "dark mode, Papirus icons, Inter font, ${cursor_theme:-Adwaita} cursor"

# ── 9. Apply now if we're already in Hyprland ──────────────────────
if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  step "Reloading the running Hyprland session"
  # full-reset: switches a session that was started with an old hyprland.conf over to hyprland.lua
  hyprctl reload full-reset >/dev/null || true
  ~/.config/hypr/scripts/bars restart || true
fi

# ── Done ───────────────────────────────────────────────────────────
printf '\n%s✓ macrice is installed.%s\n' "$bold" "$reset"
if [[ ${reboot_needed:-0} == 1 ]]; then
  echo "  • Reboot, then pick ${bold}Hyprland (uwsm-managed)${reset} on the login screen."
elif [[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  echo "  • Log out and pick ${bold}Hyprland (uwsm-managed)${reset} on the login screen."
fi
echo "  • ${bold}⌘ /${reset} shows every shortcut · the Apple menu (top left) has System Settings · ⌘Space searches apps"
((moved)) && echo "  • Your old configs are in $backup"
exit 0
