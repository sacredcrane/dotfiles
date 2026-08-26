# Dotfiles

Personal Void Linux configuration for a niri session with a Catppuccin Mocha
desktop. The status sidebar is built with Eww and POSIX shell scripts.

## Packages

- `applications`: Catppuccin themes for Chromium and Telegram
- `foot`: terminal configuration
- `gtk`: GTK 3/4 Mocha colors and desktop appearance
- `eww`: sidebar, widgets, and hardware state providers
- `fastfetch`: compact system summary
- `fuzzel`: application launcher and secure prompts
- `greetd`: system-owned greetd and tuigreet configuration
- `mako`: notification daemon theme
- `niri`: compositor configuration and session startup
- `qt`: Qt 5/6 Catppuccin theme through Kvantum
- `swaylock`: lock screen appearance
- `yazi`: terminal file manager and Catppuccin flavor
- `zellij`: terminal workspace configuration and theme

User packages follow the GNU Stow layout and can be linked into `$HOME`
independently. The `greetd` package contains root-owned files for `/etc`.

## Install

Install the base tools:

```sh
doas xbps-install -S stow eww niri foot yazi fastfetch jq gawk iw wpa_supplicant \
  curl unzip brightnessctl pipewire wireplumber mako fuzzel swayidle swaylock \
  bluez libnotify zellij kvantum greetd tuigreet
```

The bar also expects `tlp`, `tlp-pd`, `tlpctl`, and a Nerd Font with the
family name `JetBrainsMono Nerd Font Mono`.

From the repository root, create the configuration links:

```sh
stow --target="$HOME" applications eww fastfetch foot fuzzel gtk mako niri qt swaylock yazi zellij
install-app-themes
install-icon-cursor-themes
install-kvantum-theme
ya pkg install
apply-gtk-theme
```

Install the root-owned login manager configuration separately:

```sh
doas install -Dm644 greetd/etc/greetd/config.toml /etc/greetd/config.toml
doas install -Dm644 greetd/etc/tuigreet/config.toml /etc/tuigreet/config.toml
```

Remove them without deleting repository files:

```sh
stow --delete --target="$HOME" applications eww fastfetch foot fuzzel gtk mako niri qt swaylock yazi zellij
```

Existing files at the target paths must be moved or imported before Stow can
create links.

## Application themes

`install-app-themes` downloads a checksum-verified, pinned Chromium theme.
Chromium requires loading
`~/.local/share/chromium-themes/catppuccin-chrome-mocha-mauve` once from
`chrome://extensions` with Developer mode enabled. Telegram uses the official
Catppuccin cloud theme and requires confirming it once:

```sh
Telegram -- 'tg://addtheme?slug=ctp_mocha'
```

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
zellij --config zellij/.config/zellij/config.kdl setup --check
XDG_CONFIG_HOME="$PWD/yazi/.config" yazi --debug
for script in eww/.config/eww/scripts/*.sh; do sh -n "$script"; done
eww --config eww/.config/eww daemon
eww --config eww/.config/eww open sidebar
```
