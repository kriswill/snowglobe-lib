# configuration that enables as many things as possible
# so the ci.sh can cache to nix-store.earthgman.dev and check nixpkgs for failing builds
{
  pkgs,
  lib,
  config,
  ...
}:
let
  mkForce = lib.mkForce;
in
{
  # custom program options
  programs =
    let
      programNames = (builtins.attrNames (builtins.readDir ../../nixosModules/nixos/programs));
    in
    lib.genAttrs programNames (program: {
      enable = true;
    });

  snowglobe-lib = {
    gpu = {
      amd.enable = mkForce true;
      intel.enable = mkForce true;
      nvidia.enable = mkForce true;
    };
    desktop = {
      niri.enable = true;
      kde.enable = true;
    };
    libvirtd-qemu.enable = true;
  };

  hardware.enableAllFirmware = true;
}
