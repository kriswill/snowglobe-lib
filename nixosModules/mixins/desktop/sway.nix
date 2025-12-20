{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.gman.desktop.sway.enable = lib.mkEnableOption "gman's sway installation with uwsm";
  config = lib.mkIf config.gman.desktop.sway.enable {
    services = {
      swaync.enable = true;
      awww = {
        enable = true;
        flags = lib.mkDefault [
          "-f"
          "argb"
        ];
      };
    };
    programs = {
      sway = {
        enable = true;
        extraPackages = builtins.attrValues {
          inherit (pkgs)
            # idle daemon
            swayidle

            # lockscreen
            swaylock-effects

            # the bar
            waybar

            # notifications
            swaynotificationcenter
            libnotify

            # clipboard
            wl-clipboard

            # screenshots
            grim
            # also needed for desktop portal wlr
            slurp
            ;
        };
      };
      uwsm = {
        enable = true;
        waylandCompositors = {
          sway = {
            prettyName = "Sway";
            comment = "sway compositor managed by UWSM";
            binPath = "${lib.getExe config.programs.sway.package}";
          };
        };
      };
      rofi.enable = true;
      # provide a terminal
      kitty.enable = lib.mkDefault true;
    };
  };
}
