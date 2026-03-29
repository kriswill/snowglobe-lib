# default configuration for secrets management with sops
{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.snowglobe-core.sops-config;
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
      defaultSopsFormat = lib.setDefault "yaml";
      age = {
        keyFile = lib.setDefault "/var/lib/sops-nix/keys.txt";
      };
    };
  };
}
