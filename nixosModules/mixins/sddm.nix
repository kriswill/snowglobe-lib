{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.sddm;
  package = pkgs.sddm-astronaut.override {
    inherit (cfg.config) themeConfig embeddedTheme;
  };

in
{
  options.gman.sddm = {
    enable = lib.mkEnableOption "gman's sddm configuration themed with the astronaut qt6 theme";
    config = {
      themeConfig = lib.mkOption {
        description = "theme configuration for sddm astronaut theme";
        type = lib.types.attrsOf lib.types.str;
        default = { };
      };
      embeddedTheme = lib.mkOption {
        description = "which embedded theme to use from the sddm-astronaut-theme repository";
        type = lib.types.str;
        default = "astronaut";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm = {
      enable = lib.mkDefault true;
      wayland.enable = true;
      theme = "sddm-astronaut-theme";

      # astronaut requires sddm from plasma 6 (default is 5)
      package = pkgs.kdePackages.sddm;

      extraPackages = [ package ];
    };

    environment.systemPackages = [
      package
    ];

    gman.sddm.config.themeConfig = {
      # why is this disabled by default?
      AllowUppercaseLettersInUsernames = lib.mkDefault "true";

      FullBlur = lib.mkDefault "false";
      PartialBlur = lib.mkDefault "false";
    };
  };
}
