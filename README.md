# Dotfiles

Personal Void Linux configuration for a niri session with a Catppuccin Mocha
desktop. The status sidebar is built with Eww and POSIX shell scripts.

## Packages

- `foot`: terminal configuration
- `gtk`: GTK 3/4 Mocha colors and desktop appearance
- `eww`: sidebar, widgets, and hardware state providers
- `fuzzel`: application launcher and secure prompts
- `mako`: notification daemon theme
- `niri`: compositor configuration and session startup
- `yazi`: terminal file manager and Catppuccin flavor

Each top-level package follows the GNU Stow layout and can be linked into
`$HOME` independently.

## Install

Install the base tools:

```sh
doas xbps-install -S stow eww niri foot yazi jq gawk iw wpa_supplicant \
  brightnessctl pipewire wireplumber mako fuzzel swayidle swaylock \
  bluez libnotify
```

The bar also expects `tlp`, `tlp-pd`, `tlpctl`, and a Nerd Font with the
family name `JetBrainsMono Nerd Font Mono`.

From the repository root, create the configuration links:

```sh
stow --target="$HOME" eww foot fuzzel gtk mako niri yazi
ya pkg install
apply-gtk-theme
```

Remove them without deleting repository files:

```sh
stow --delete --target="$HOME" eww foot fuzzel gtk mako niri yazi
```

Existing files at the target paths must be moved or imported before Stow can
create links.

## Connectivity

The Wi-Fi popup manages `wpa_supplicant` directly. Its control interface must
be available to the desktop user and `update_config=1` must be enabled before
new profiles can be persisted. WPA2 and WPA3 passwords are entered in a
dedicated Fuzzel namespace that niri blocks from screen capture. Passwords are
not stored in Eww state or passed as command-line arguments.

Enable the Void Linux Bluetooth service:

```sh
doas ln -s /etc/sv/bluetoothd /var/service/
```

Bluetooth pairing uses the BlueZ `NoInputNoOutput` agent and therefore targets
JustWorks devices such as most headphones and gamepads. Devices that require a
PIN or passkey need a separate interactive BlueZ agent.

## Validate

```sh
niri validate -c niri/.config/niri/config.kdl
foot --config=foot/.config/foot/foot.ini --check-config
fuzzel --config=fuzzel/.config/fuzzel/fuzzel.ini --check-config
XDG_CONFIG_HOME="$PWD/yazi/.config" yazi --debug
for script in eww/.config/eww/scripts/*.sh; do sh -n "$script"; done
eww --config eww/.config/eww daemon
eww --config eww/.config/eww open sidebar
```
