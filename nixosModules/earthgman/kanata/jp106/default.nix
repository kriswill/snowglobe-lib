{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.kanata.jp106;
in
{
  options.earthgman.kanata.jp106 = {
    enable = lib.mkEnableOption "EarthGman's personal keymap for a jp106 keyboard layout";
    affectedDevices = lib.mkOption {
      description = ''
        paths to keyboard devices which will be affected by this kanata configuration.
      '';
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    # add to PATH
    environment.systemPackages = [ config.services.kanata.package ];
    # ensure that the keyboard layout is configured with x and virtual consoles
    services.xserver.xkb.layout = "jp";
    services.kanata = {
      enable = true;
      keyboards = {
        earthgman-jp106 = {
          devices = cfg.affectedDevices;
          extraDefCfg = "process-unmapped-keys yes";
          config = builtins.readFile ./config.kbd;
        };
      };
    };
  };
}
