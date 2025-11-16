**EarthGman's Main Nix Flake V8**
Now without home-manager!

This flake contains my NixOS modules, nix package derivations, nix functions, NixOS installation environment and installation script.

It is highly maintained by myself and a few others, and can be easily imported into your own NixOS flake for expanded functionality.

If you are interested in Nix or NixOS, then this repository can serve as a well-refined example and reference of what can be accomplished with the language and OS.

Note - This flake no longer provides any home-manager modules. You will have to manage user dotfiles yourself or just use mine (not recommended).

------------------------------------------------------------------------

# Getting Started

NixOS is known for being a very confusing distribution with little documentation.

Additionally, the official installer refuses to expose users to nix flakes (which are the real superpower of nix) out of the box, opting to use nix channels which are basically deprecated at this point.

This framework aims to be an improvement of the default NixOS experience by providing a more structured configuration framework for modularity and expandability.

To obtain the installer navigate to https://cache.earthgman.net and download the nixos-installer.iso and its sha256sum (only supports x86_64 at this time).

If you don't want to put an iso image from a random guy on the internet into your PC, you can build the installer iso yourself. [Instructions](https://github.com/EarthGman/nix-config/blob/main/docs/build-iso.md)

if installing on bare metal, Use a program such as rufus, balena-etcher, or dd to flash the iso image to a usb stick.

------------------------------------------------------------------------

# Bug tracker - Last updated: 11-09-2025

- sddm is known to not properly restart when exiting Hyprland. This happens seemingly randomly and I don't know how to fix it.
  if you encounter this bug, log in via another tty and restart display-manager.service

- xwayland apps within wayland sessions have a bug in which the mouse will not be able to interact with the window if your monitor position contains a negative coordinate.
  This bug only affects setups with more than 1 monitor.

- steam notifications appear in the middle of the screen on niri

# Personal Notes
Imperative actions after install
- install dotfiles
- login to discord
- login to steam
- import gpg private keys
- ssh-add ssh private key
- import neomutt email accounts
- install protonup for steam
- /etc/nixos -> ~/src/github/earthgman/nix-config
- Install the English Dictionary extension for libreoffice (otherwise the spell checker wont work)
- setup any VMs
- reinstall wine/bottles programs
