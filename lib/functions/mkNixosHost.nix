{ outputs, ... }:
let
  # allow use of custom + nixpkgs lib functions
  lib = outputs.lib;
in
{
  hostname ? "nixos", # name your system
  firmware ? "UEFI", # firmware implementation, one of UEFI or BIOS
  cpu-vendor ? null, # cpu vendor, "intel" or "amd"
  gpu-vendors ? [ ], # list of gpu vendors, "intel" "nvidia" "amd"
  isQemu ? false, # are we in a VM?
  desktop ? null, # desktop environment?
  sopsFile ? null,
  stateVersion ? "26.05", # initial release of nixos which this machine was installed
  arch ? "x86_64-linux", # target cpu architecture
  modules ? [ ], # send extra modules to the function
  specialArgs ? { }, # send extra special arguments to the function
  configuration ? null, # path to the directory containing this hosts configuration
}:
lib.nixosSystem {
  system = arch; # used for legacy nixos < 22.05, but it doesn't hurt to have it here
  specialArgs = {
    # apply custom lib functions
    inherit lib;
  }
  // specialArgs;
  modules =
    let
      hostConfig =
        if (configuration != null) then
          if builtins.pathExists (configuration) then [ configuration ] else [ ]
        else
          [ ];

      myModules = [ outputs.nixosModules.earthgman ];
    in
    [
      {
        # enable my modules
        earthgman.enable = lib.setDefault true;

        # set secrets file
        sops.defaultSopsFile = lib.mkIf (sopsFile != null) sopsFile;

        # populate system options with hardware specific config
        system = {
          name = hostname;
          inherit
            stateVersion
            cpu-vendor
            gpu-vendors
            isQemu
            desktop
            firmware
            arch
            ;
        };
      }
    ]
    ++ hostConfig
    ++ myModules
    # extra modules passed to the function
    ++ modules;
}
