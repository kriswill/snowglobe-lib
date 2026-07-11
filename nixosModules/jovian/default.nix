{ flake }:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  inputs = flake.inputs;
  cfg = config.jovian;
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
in
{
  imports = [
    inputs.jovian-nixos.nixosModules.jovian
  ];

  # TODO pnpm_9 is insecure
  nixpkgs.config.permittedInsecurePackages = lib.mkIf cfg.decky-loader.enable [
    "pnpm-9.15.9"
  ];

  jovian = {
    steam = {
      enable = slib.setDefault true;
      autoStart = slib.setDefault true;
    };

    decky-loader = {
      enable = slib.setDefault true;
    };
  };

  # disable ly as jovian enables sddm
  services.displayManager.ly.enable = false;

  system.userActivationScripts = {
    enable-decky = lib.mkIf cfg.decky-loader.enable ''
      ENABLE_DEBUGGING_PATH="$HOME/.steam/steam/.cef-enable-remote-debugging"
      if [ ! -e "$ENABLE_DEBUGGING_PATH" ]; then
        touch "$ENABLE_DEBUGGING_PATH"
      fi
    '';
  };

}
