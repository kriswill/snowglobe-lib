{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.kanata.jp106;
in
{
  options.gman.kanata.jp106 = {
    enable = lib.mkEnableOption "gman's personal keymap for a jp106 keyboard layout";
    config.devices = lib.mkOption {
      description = ''
        paths to keyboard devices which will be affected by this kanata configuration.
      '';
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ config.services.kanata.package ];
    services.kanata = {
      enable = true;
      keyboards = {
        gman-jp106 = {
          devices = cfg.config.devices;
          extraDefConfig = "process-unmapped-keys yes";
          config = builtins.readFile ./config.kbd;
        };
      };
    };
  };
}
