{ lib, config, ... }:
{
  options.gman.nh.enable = lib.mkEnableOption "gman's nix helper configuration";
  config = lib.mkIf config.gman.nh.enable {
    programs.nh = {
      enable = lib.mkDefault true;
      clean.enable = lib.mkDefault true;
    };

    # bug introduced somewhere around nh 4.1 where it will always fail the check for flakes
    environment.variables = {
      NH_NO_CHECKS = "1";
    };
  };
}
