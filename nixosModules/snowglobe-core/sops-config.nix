# default configuration for secrets management with sops
{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.snowglobe-core.sops-config;
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-core.sops-config.enable = lib.mkEnableOption "Snowglobe-Core's sops-nix configuration";
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
