{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.android;
in
{
  options.gman.android.enable = lib.mkEnableOption "gman's android configuration";
  config = lib.mkIf cfg.enable {
    programs = {
      # be sure to add your user to adbusers group
      kdeconnect = {
        enable = lib.mkDefault true;
        package =
          if (config.meta.desktop == "gnome") then
            pkgs.gnomeExtensions.gsconnect
          else
            pkgs.kdePackages.kdeconnect-kde;
      };
      scrcpy.enable = lib.mkDefault true;
    };

    environment.systemPackages = builtins.attrValues {
      inherit (pkgs)
        android-tools
        apksigner
        ;
    };

    services.kdeconnect-indicator.enable = lib.mkDefault config.meta.desktop != "";
  };
}
