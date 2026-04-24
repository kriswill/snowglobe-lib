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
let
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
in
{
  imports = [
    inputs.jovian-nixos.nixosModules.jovian
  ];

  jovian = {
    steam = {
      enable = slib.setDefault true;
      autoStart = slib.setDefault true;
    };

    # TODO add to a user activation script
    # IMPERATIVE ACTION: touch ~/.steam/steam/.cef-enable-remote-debugging
    decky-loader.enable = slib.setDefault true;
  };
}
