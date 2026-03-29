{
  pkgs,
  lib,
  config,
  ...
}:
let
  module-name = "flatpak-config";
  cfg = config.earthgman.${module-name};
in
{
  options.earthgman.${module-name} = {
    enable = lib.mkEnableOption "EarthGman's flatpak configuration";
    frontend = lib.mkOption {
      description = "Flatpak frontend to use";
      type = lib.types.str;
      default = "gnome-software";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.flatpak.enable = true;

        # automatically add flatpak to whatever frontend you want to use
        systemd.services.flatpak-repo = {
          wantedBy = [ "multi-user.target" ];
          path = [ pkgs.flatpak ];
          script = ''
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
          '';
        };
      }
      (lib.mkIf (config.earthgman.desktop.enable) {
        programs.${cfg.frontend}.enable = lib.setDefault true;
      })
    ]
  );
}
