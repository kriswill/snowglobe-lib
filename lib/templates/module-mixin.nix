{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.mixin-name;
in
{
  options.gman.mixin-name = {
    enable = lib.mkEnableOption "gman's mixin-name configuration";
  };

  config = lib.mkIf cfg.enable {
    # modules
  };
}
