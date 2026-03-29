# wrapper for my 2 display-managers of choice sddm and ly, could add support for gdm in the future
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-core.display-manager;
  sddm-astronaut-theme = pkgs.sddm-astronaut.override {
    themeConfig = cfg.sddm.themeConfig;
    embeddedTheme = cfg.sddm.embeddedTheme;
  };
in
{
  options.snowglobe-core.display-manager = {
    enable = lib.mkEnableOption "Snowglobe-Core's display-manager configurations";
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
      embeddedTheme = lib.mkOption {
        description = ''
          the imbedded theme to use from sddm-astronaut
          Warning: Modifying themePackage will nullify the values in this option
        '';
        default = "astronaut";
        type = lib.types.str;
      };
      themeConfig = lib.mkOption {
        description = ''
          [general] settings written to your theme's theme.conf
          Warning: Modifying themePackage will nullify the values in this option.
        '';
        default = { };
        type = lib.types.attrsOf lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = lib.mkIf (cfg.display-manager != "ly" && cfg.display-manager != "sddm") [
          {
            assertion = false;
            message = "Invalid value for display-manager. Possible values are: 'ly' or 'sddm'";
          }
        ];
      }
      (lib.mkIf (cfg.display-manager == "sddm") {
        services.displayManager.sddm = {
          enable = lib.mkDefault true;
          wayland.enable = true;
          theme = lib.mkDefault "sddm-astronaut-theme";

          # astronaut requires sddm from plasma 6 (default is 5)
          package = pkgs.kdePackages.sddm;

          extraPackages = [ cfg.sddm.themePackage ];
        };

        environment.systemPackages = [
          cfg.sddm.themePackage
        ];

        snowglobe-core.display-manager.sddm.themeConfig = {
          AllowUppercaseLettersInUsernames = lib.mkDefault "true";
          FullBlur = lib.mkDefault "false";
          PartialBlur = lib.mkDefault "false";
        };
      })
      (lib.mkIf (cfg.display-manager == "ly") {
        services.displayManager.ly = {
          enable = true;
        };
      })
    ]
  );
}
