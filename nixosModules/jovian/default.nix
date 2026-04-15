{
  inputs,
  lib,
  ...
}:
{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.jovian-nixos.nixosModules.jovian
  ];

  jovian = {
    steam = {
      enable = lib.setDefault true;
      autoStart = lib.setDefault true;
    };

    # TODO add to a user activation script
    # IMPERATIVE ACTION: touch ~/.steam/steam/.cef-enable-remote-debugging
    decky-loader.enable = lib.setDefault true;
  };
}
