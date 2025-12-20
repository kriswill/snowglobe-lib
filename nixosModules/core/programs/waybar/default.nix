{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "waybar";
  cfg = config.programs.${program-name};
in
{
  # patch to the waybar service, which adds the default installation directory for NixOS
  # https://github.com/nix-community/home-manager/issues/4099
  config = lib.mkIf cfg.enable {
    systemd.user.services.waybar.path = [ "/run/current-system/sw" ];
  };
}
