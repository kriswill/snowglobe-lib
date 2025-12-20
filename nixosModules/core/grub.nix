{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.boot.loader.grub;
in
{
  options.boot.loader.grub = {
    themeName = lib.mkOption {
      description = "name of the theme from pkgs/themes/grub";
      type = lib.types.str;
      default = "nixos-grub";
    };

    themeConfig = lib.mkOption {
      description = "extra config options for grub themes";
      default = { };
      type = lib.types.attrsOf lib.types.str;
    };
  };

  config = {
    boot.loader.grub = {
      theme = lib.mkDefault (
        pkgs.${cfg.themeName}.override {
          inherit (cfg) themeConfig;
        }
      );
    };
  };
}
