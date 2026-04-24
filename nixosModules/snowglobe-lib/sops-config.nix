# default configuration for secrets management with sops
{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.snowglobe-lib.sops-config;
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-lib.sops-config.enable = lib.mkEnableOption "Snowglobe-Lib's sops-nix configuration";
  config = lib.mkIf cfg.enable {
    environment.systemPackages = builtins.attrValues {
      inherit (pkgs)
        sops
        age
        ;
    };
    sops = {
      defaultSopsFormat = slib.setDefault "yaml";
      age = {
        keyFile = slib.setDefault "/var/lib/sops-nix/keys.txt";
      };
    };
  };
}
