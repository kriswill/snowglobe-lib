**A down to earth nix module set that is portable and easy to use**

This flake contains my NixOS modules, nix package derivations, nix functions, and NixOS installation environment + script.

It is highly maintained by myself and a few others, and can be easily imported into your own NixOS flake for expanded functionality.

If you are interested in Nix or NixOS, then this repository can serve as a well-refined example and reference of what can be accomplished with the language and OS.

Note - This flake no longer provides any home-manager modules. You will have to manage user dotfiles yourself or just use mine (not recommended).

------------------------------------------------------------------------

# Getting Started

NixOS is known for being a very confusing distribution with little documentation.

Additionally, the official installer refuses to expose users to nix flakes (which are the real superpower of nix) out of the box, opting to use nix channels which are basically deprecated at this point.

This framework aims to be an improvement of the default NixOS experience by providing a more structured configuration framework for modularity and expandability.

To obtain the installer navigate to https://cache.earthgman.dev and download binaries/nixos-installer.iso and its sha256sum (only supports x86_64 at this time).

If you don't want to put an iso image from a random guy on the internet into your PC, you can build the installer iso yourself. See docs/build-iso.md

if installing on bare metal, Use a program such as rufus, balena-etcher, or dd to flash the iso image to a usb stick.
