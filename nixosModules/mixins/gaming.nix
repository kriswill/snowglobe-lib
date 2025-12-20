# triggered by the gaming specialization from the installer
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.gaming;
in
{
  options.gman.gaming = {
    enable = lib.mkEnableOption "gman's gaming PC configuration";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        gman = {
          steam.enable = true;
          hardware-tools.enable = lib.mkDefault true;
        };
        programs = {
          lutris.enable = lib.mkDefault true;
        };
      }
    ]
  );
}
