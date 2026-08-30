# Dotfiles

Personal Void Linux configuration for a niri session with a Catppuccin Mocha
desktop. The status sidebar is built with Eww and POSIX shell scripts.

## Packages

- `applications`: Catppuccin themes for Chromium and Telegram
- `boot`: checksum-verified Catppuccin GRUB and Plymouth installer
- `foot`: terminal configuration
- `gtk`: GTK 3/4 Mocha colors and desktop appearance
- `eww`: sidebar, widgets, and hardware state providers
- `fastfetch`: compact system summary
- `fuzzel`: application launcher and secure prompts
- `greetd`: system-owned ReGreet and fallback Tuigreet configuration
- `mako`: notification daemon theme
- `niri`: compositor configuration and session startup
- `qt`: Qt 5/6 Catppuccin theme through Kvantum
- `swaylock`: lock screen appearance
- `swayidle`: automatic lock and display power management
- `wallpaper`: desktop and lock-screen background
- `yazi`: terminal file manager and Catppuccin flavor
- `zellij`: terminal workspace configuration and theme
- `xdg-desktop-portal`: explicit GTK, GNOME, and Secret portal selection

User packages follow the GNU Stow layout and can be linked into `$HOME`
independently. The `greetd` package contains root-owned files for `/etc`.

## Install

Install the base tools:

```sh
doas xbps-install -S stow eww niri foot yazi fastfetch jq gawk iw wpa_supplicant \
  curl unzip brightnessctl pipewire wireplumber mako fuzzel swayidle swaylock \
  bluez libnotify zellij kvantum greetd ReGreet cage tuigreet polkit-gnome \
  gnome-keyring xdg-desktop-portal xdg-desktop-portal-gtk \
  xdg-desktop-portal-gnome plymouth plymouth-data
```

The bar also expects `tlp`, `tlp-pd`, `tlpctl`, and a Nerd Font with the
family name `JetBrainsMono Nerd Font Mono`.

From the repository root, create the configuration links:

```sh
stow --target="$HOME" applications eww fastfetch foot fuzzel gtk mako niri qt swayidle swaylock wallpaper xdg-desktop-portal yazi zellij
install-app-themes
install-icon-cursor-themes
install-kvantum-theme
ya pkg install
apply-gtk-theme
```

The icon installer combines Papirus with the official Catppuccin Mocha Mauve
folder overlay and installs the matching Catppuccin cursor theme.

Install the root-owned login manager configuration and greeter background
separately:

```sh
doas ./greetd/install
```

ReGreet runs inside Cage so that the greeter compositor releases the active VT
before the user niri session takes over. To allow its power buttons, grant the
`_greeter` user only the two required commands in `/etc/doas.conf`:

```text
permit nopass _greeter as root cmd /usr/bin/reboot args
permit nopass _greeter as root cmd /usr/bin/poweroff args
```

The greeter installer copies the desktop Papirus and Catppuccin cursor themes
to `/usr/local/share/icons`, where the `_greeter` user can access them. Run the
user icon installer before reinstalling the greeter configuration.

Restore the terminal greeter if the graphical greeter cannot start:

```sh
doas install -Dm644 greetd/etc/greetd/config.tuigreet.toml /etc/greetd/config.toml
```

Remove them without deleting repository files:

```sh
stow --delete --target="$HOME" applications eww fastfetch foot fuzzel gtk mako niri qt swayidle swaylock wallpaper xdg-desktop-portal yazi zellij
```

Existing files at the target paths must be moved or imported before Stow can
create links.

## Boot theme

Install the pinned Catppuccin Mocha themes after installing Plymouth:

```sh
doas ./boot/install
```

The installer enables Plymouth in dracut, adds `quiet splash`, pins the GRUB
default to kernel `6.18.45_2`, rebuilds every initramfs, and validates a newly
generated GRUB configuration before activating it. Existing configuration is
backed up once with the `.catppuccin-backup` suffix.

Restore the previous GRUB configuration if needed:

```sh
doas cp /etc/default/grub.catppuccin-backup /etc/default/grub
doas cp /boot/grub/grub.cfg.catppuccin-backup /boot/grub/grub.cfg
```

## Application themes

`install-app-themes` downloads a checksum-verified, pinned Chromium theme.
Chromium requires loading
`~/.local/share/chromium-themes/catppuccin-chrome-mocha-mauve` once from
`chrome://extensions` with Developer mode enabled. Telegram uses the official
Catppuccin cloud theme and requires confirming it once:

```sh
Telegram -- 'tg://addtheme?slug=ctp_mocha'
```

## Keyring

Greetd already unlocks the GNOME Login keyring through PAM. If Chromium asks
to unlock it after every login, install `seahorse`, open the `Login` keyring,
and use **Change Password** to set it to the current Unix login password:

```sh
doas xbps-install seahorse
seahorse
```

Log out after changing the password so PAM can verify automatic unlock on the
next login. This keeps Chromium credentials encrypted; avoid
`--password-store=basic` unless unencrypted storage is intentional.

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
sh -n boot/install greetd/install swaylock/.local/bin/lock-screen
foot --config=foot/.config/foot/foot.ini --check-config
fuzzel --config=fuzzel/.config/fuzzel/fuzzel.ini --check-config
zellij --config zellij/.config/zellij/config.kdl setup --check
XDG_CONFIG_HOME="$PWD/yazi/.config" yazi --debug
for script in eww/.config/eww/scripts/*.sh; do sh -n "$script"; done
eww --config eww/.config/eww daemon
eww --config eww/.config/eww open sidebar
```
