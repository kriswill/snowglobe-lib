{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.display-manager;
  sddm-astronaut-theme = pkgs.sddm-astronaut.override {
    themeConfig = cfg.config.sddm.themeConfig;
  };
in
{
  options.gman.display-manager = {
    enable = lib.mkEnableOption "gman's display-manager module";
    config = {
      display-manager = lib.mkOption {
        description = "display-manager program and configuration to use";
        type = lib.types.str;
        default = "sddm";
      };
      sddm = {
        themePackage = lib.mkOption {
          description = "The packaged config for your sddm theme";
          default = sddm-astronaut-theme;
          type = lib.types.package;
        };
        themeConfig = lib.mkOption {
          description = "[general] settings written to your theme's theme.conf";
          default = { };
          type = lib.types.attrsOf lib.types.str;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        warnings = lib.mkIf (cfg.config.display-manager != "ly" && cfg.config.display-manager != "sddm") [
          "Invalid value for display-manager. Possible values are: 'ly' or 'sddm'"
        ];
      }
      (lib.mkIf (cfg.config.display-manager == "sddm") {
        services.displayManager.sddm = {
          enable = lib.mkDefault true;
          wayland.enable = true;
          theme = lib.mkDefault "sddm-astronaut-theme";

          # astronaut requires sddm from plasma 6 (default is 5)
          package = pkgs.kdePackages.sddm;

          extraPackages = [ cfg.config.sddm.themePackage ];
        };

        environment.systemPackages = [
          cfg.config.sddm.themePackage
        ];

        gman.display-manager.config.sddm.themeConfig = {
          AllowUppercaseLettersInUsernames = lib.mkDefault "true";
          FullBlur = lib.mkDefault "false";
          PartialBlur = lib.mkDefault "false";
        };
      })
      (lib.mkIf (cfg.config.display-manager == "ly") {
        services.displayManager.ly = {
          enable = true;
        };
      })
    ]
  );
}
