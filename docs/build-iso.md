NixOS installers are simply configurations compiled to bootable iso format. All source code for the configuration is available at hosts/nixos-installer/default.nix

# Supported systems

- x86_64
- aarch64

To begin building the custom installer you will first need to install nix and enable flake support.
https://nixos.org/download/

Pull the repository:

```sh
git clone https://codeberg.org/earthgman/nix-modules --depth 1
```

Then install nixos-generate using a nix shell

```sh
nix shell nixpkgs#nixos-generate
```

cd to the root of the repository and run

```
nixos-generate --flake .#nixos-installer-x86_64 -f iso -o result
```

Ensure that you use the correct cpu architecture from supported systems for your machine

a "result" symlink to the /nix/store will be created. You can then cp the iso from the directory result/iso (mv does not work as the store is immutable)

# Cleanup

- exit the nix shell with `exit`
- Remove the iso image and its dependencies from the /nix/store

```
sudo nix-collect-garbage -d
```

