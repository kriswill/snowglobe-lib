{
  pkgs,
  lib,
  config,
  ...
}:
let
  module-name = "flatpak-config";
  cfg = config.snowglobe-lib.${module-name};
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-lib.${module-name} = {
    enable = lib.mkEnableOption "Snowglobe-Lib's flatpak configuration";
    frontend = lib.mkOption {
      description = "Flatpak frontend to use";
      type = lib.types.str;
      default = "gnome-software";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # automatically add flatpak to whatever frontend you want to use
        systemd.services.flatpak-repo = {
          wantedBy = [ "multi-user.target" ];
          path = [ pkgs.flatpak ];
          script = ''
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
          '';
        };
      }
      (lib.mkIf (config.snowglobe-lib.desktop.enable) {
        programs.${cfg.frontend}.enable = slib.setDefault true;
      })
    ]
  );
}
