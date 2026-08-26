# Dotfiles

Personal Void Linux configuration for a niri session with a Catppuccin Mocha
desktop. The status sidebar is built with Eww and POSIX shell scripts.

## Packages

- `alacritty`: terminal configuration
- `eww`: sidebar, widgets, and hardware state providers
- `niri`: compositor configuration and session startup

Each top-level package follows the GNU Stow layout and can be linked into
`$HOME` independently.

## Install

Install the base tools:

```sh
sudo xbps-install -S stow eww niri alacritty jq gawk iw wpa_supplicant \
  brightnessctl pipewire wireplumber mako fuzzel swayidle swaylock \
  polkit-gnome
```

The bar also expects `tlp`, `tlp-pd`, `tlpctl`, and a Nerd Font with the
family name `JetBrainsMono Nerd Font Mono`.

From the repository root, create the configuration links:

```sh
stow --target="$HOME" alacritty eww niri
```

Remove them without deleting repository files:

```sh
stow --delete --target="$HOME" alacritty eww niri
```

Existing files at the target paths must be moved or imported before Stow can
create links.

## Validate

```sh
niri validate -c niri/.config/niri/config.kdl
for script in eww/.config/eww/scripts/*.sh; do sh -n "$script"; done
eww --config eww/.config/eww daemon
eww --config eww/.config/eww open sidebar
```
