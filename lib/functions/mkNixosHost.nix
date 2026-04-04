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
  isVM ? false, # are we in a VM?
  desktop ? null, # desktop environment?
  sopsFile ? null,
  stateVersion ? "26.05", # initial release of nixos which this machine was installed
  system ? "x86_64-linux", # target cpu architecture
  modules ? [ ], # send extra modules to the function
  specialArgs ? { }, # send extra special arguments to the function
  configDir ? null, # path to the directory containing this hosts configuration
}:
lib.nixosSystem {
  inherit system; # used for legacy nixos < 22.05, but it doesn't hurt to have it here
  specialArgs = {
    # apply custom lib functions
    inherit lib;
  }
  // specialArgs;
  modules =
    let
      importModules =
        moduleDir:
        if (configDir != null) then
          if (builtins.pathExists (configDir + "/${moduleDir}")) then
            (lib.importModules (configDir + "/${moduleDir}") { })
          else
            [ ]
        else
          [ ];

      hostConfig =
        if (configDir != null) then
          if builtins.pathExists (configDir) then [ (configDir + "/configuration.nix") ] else [ ]
        else
          [ ];

      userConfig = importModules "users";
      programConfig = importModules "programs";
      serviceConfig = importModules "services";

      snowglobeCore = [ outputs.nixosModules.snowglobe-core ];
    in
    [
      {
        snowglobe-core.enable = lib.setDefault true;

        # set secrets file
        sops.defaultSopsFile = lib.mkIf (sopsFile != null) sopsFile;

        # populate system options with hardware specific config
        system = {
          name = hostname;
          arch = system;
          inherit
            stateVersion
            cpu-vendor
            gpu-vendors
            isVM
            desktop
            firmware
            ;
        };
      }
    ]
    ++ hostConfig
    ++ programConfig
    ++ serviceConfig
    ++ userConfig
    ++ snowglobeCore
    # extra modules passed to the function
    ++ modules;
}
