{
  pkgs,
  lib,
  config,
  ...
}:
{
  # add labwc-session.target
  systemd.packages = lib.optionals config.programs.labwc.enable [ config.programs.labwc.package ];

  # ly does not allow services to start on login
  # https://codeberg.org/fairyglade/ly/issues/706
  systemd.services.display-manager.environment.XDG_CURRENT_DESKTOP =
    lib.mkIf (config.services.displayManager.ly.enable) "X-NIXOS-SYSTEMD-AWARE";
}
