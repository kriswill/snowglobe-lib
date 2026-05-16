{
  pkgs,
  lib,
  config,
  ...
}:
{
  # add labwc-session.target
  systemd.packages = lib.optionals config.programs.labwc.enable [ config.programs.labwc.package ];
}
