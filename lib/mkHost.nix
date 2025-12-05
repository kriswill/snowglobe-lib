# wrapper for lib.nixosSystem
{ inputs, outputs, ... }:
let
  lib = outputs.lib;
in
{
  hostname, # name your PC
  bios ? "UEFI", # bios type: one of "legacy" or "UEFI"
  cpu ? "", # cpu brand (amd, intel)
  gpu ? "", # gpu brand (amd, intel, nvidia)
  desktop ? "", # what desktop? "gnome" "hyprland" or "sway"
  specialization ? "", # what will this machine be used for (determined by installer)
  vm ? false, # is this a virtual machine?
  secretsFile ? null, # path to the default secrets file
  system ? "x86_64-linux", # what cpu architecture?
  # TODO Update me in may
  stateVersion ? "26.05", # what version of nixos was this machine initalized?
  configDir ? null, # directory for extra host configuration
  extraModules ? [ ], # additional modules from your own flake
  extraSpecialArgs ? { }, # additional arguments passed to nixosSystem SpecialArgs
}:
lib.nixosSystem {
  inherit system; # used for legacy nixos < 22.05, but it doesn't hurt to have it
  specialArgs = {
    inherit lib;
  }
  // extraSpecialArgs;
  modules =
    let
      host =
        if (configDir != null) then if builtins.pathExists (configDir) then [ configDir ] else [ ] else [ ];

      nixosUsers =
        if (host != [ ]) then
          if builtins.pathExists (configDir + "/users") then lib.autoImport (configDir + "/users") else [ ]
        else
          [ ];
    in
    [
      {
        # enable my default module and mixins
        gman = {
          enable = lib.mkDefault true;
        };

        nixpkgs = {
          overlays = builtins.attrValues outputs.overlays;
        };

        system.stateVersion = stateVersion;

        meta = {
          inherit
            hostname
            cpu
            gpu
            bios
            desktop
            vm
            specialization
            secretsFile
            ;
        };
      }
    ]
    ++ [ outputs.nixosModules.gman ]
    ++ nixosUsers
    ++ host
    ++ extraModules;
}
