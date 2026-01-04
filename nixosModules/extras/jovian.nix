# Jovian does not allow itself to be toggled off once the modules have been imported.
# so just provide a seperate module set for enabling the jovian configuration
{
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.jovian-nixos.nixosModules.jovian ];

  # remove sddm config
  gman.sddm.enable = false;

  jovian = {
    steam = {
      enable = lib.mkDefault true;
      autoStart = lib.mkDefault true;
    };

    # IMPERATIVE ACTION REQUIRED: touch ~/.steam/steam/.cef-enable-remote-debugging
    # Taken care of during install
    decky-loader.enable = lib.mkDefault true;

    hardware.has.amd.gpu = lib.mkDefault true;
  };
}
