{
  inputs,
  outputs,
  lib,
  self,
  ...
}:
let
  slib = outputs.lib;
in
{
  hostname ? "nixos", # name your system
  firmware ? "UEFI", # firmware implementation, one of UEFI or BIOS
  cpu-vendor ? null, # cpu vendor, "intel" or "amd"
  gpu-vendors ? [ ], # list of gpu vendors, "intel" "nvidia" "amd"
  isVM ? false, # are we in a VM?
  stateVersion ? "26.05", # initial release of nixos which this machine was installed
  system ? "x86_64-linux", # target cpu architecture
  modules ? [ ], # send extra modules to the function
  specialArgs ? { }, # send extra special arguments to the function
  configDir ? self + /${hostname}, # path to the directory containing this hosts configuration
}:
lib.nixosSystem {
  inherit system; # used for legacy nixos < 22.05, but it doesn't hurt to have it here
  inherit specialArgs;
  modules =
    let
      # hostConfig = if builtins.pathExists (configDir) then inputs.import-tree configDir else { };
      hostConfig = inputs.import-tree configDir;
    in
    [ outputs.nixosModules.default ]
    ++ [
      {
        snowglobe-lib.enable = slib.setDefault true;
        nixpkgs.hostPlatform = system;

        # set secrets file
        sops.defaultSopsFile = slib.setDefault "${configDir}/secrets.yaml";

        # populate system options with hardware specific config
        system = {
          inherit stateVersion;
          name = hostname;
        };
        snowglobe-lib.system = {
          inherit
            cpu-vendor
            gpu-vendors
            isVM
            firmware
            ;
        };
      }
    ]
    ++ [ hostConfig ]
    # extra modules passed to the function
    ++ modules;
}
