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
  options.gman.kanata.jp106.enable =
    lib.mkEnableOption "gman's personal keymap for a jp106 keyboard layout";
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.kanata ];
    services.kanata = {
      enable = true;
      keyboards = {
        default = {
          extraDefCfg = "process-unmapped-keys yes";
          config = builtins.readFile ./config.kbd;
        };
      };
    };
  };
}
