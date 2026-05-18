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

  # disable ly as jovian enables sddm
  services.displayManager.ly.enable = false;

  system.userActivationScripts = {
    enable-decky = ''
      ENABLE_DEBUGGING_PATH="$HOME/.steam/steam/.cef-enable-remote-debugging"
      if [ ! -e "$ENABLE_DEBUGGING_PATH" ]; then
        touch "$ENABLE_DEBUGGING_PATH"
      fi
    '';
  };

}
