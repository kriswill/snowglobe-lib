# configuration that enables as many things as possible
# so the ci.sh can cache to nix-store.earthgman.dev and check nixpkgs for failing builds
{
  pkgs,
  lib,
  config,
  outputs,
  ...
}:
let
  mkForce = lib.mkForce;
in
{
  # build decky and other jovian plugins
  imports = [ outputs.nixosModules.jovian ];
  jovian.steam = {
    user = "bob";
    desktopSession = "niri";
  };

  services.displayManager.sddm.enable = lib.mkForce false;
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
      labwc.enable = true;
    };
    libvirtd-qemu.enable = true;
    profiles = {
      office.enable = true;
      hacker-mode.enable = true;
      hardware-tools.enable = true;
      nix-tools.enable = true;
      gaming.enable = true;
    };
  };

  hardware.enableAllFirmware = true;

  # add all custom packages
  environment.systemPackages =
    lib.forEach (builtins.attrNames (
      import ../../packages {
        inherit pkgs;
      }
    )) (package: pkgs.${package})
    # extra packages I want to check
    ++ (with pkgs; [
      ly
    ]);
}
