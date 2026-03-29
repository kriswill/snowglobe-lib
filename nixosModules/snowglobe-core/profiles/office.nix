{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-core.profiles.office;
in
{
  options.snowglobe-core.profiles.office = {
    enable = lib.mkEnableOption "tools and programs typically found in an office setting";
  };

  config = lib.mkIf cfg.enable {
    # autodiscovery and configuration of printers and printing drivers
    snowglobe-core.printing-config.enable = true;

    programs = {
      # email
      thunderbird.enable = lib.setDefault true;
      # open source MSoffice
      libreoffice.enable = lib.setDefault true;
      # image editor
      gimp.enable = lib.setDefault true;
      # provide chromium as a backup browser in case something on firefox doesn't work due to poor web engineering
      chromium.enable = lib.setDefault true;
    };
  };
}
