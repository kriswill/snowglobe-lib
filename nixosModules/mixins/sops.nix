{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.gman.sops;
in
{
  options.gman.sops.enable = lib.mkEnableOption "gman's sops-nix configuration";
  config = lib.mkIf cfg.enable {
    environment.systemPackages = builtins.attrValues {
      inherit (pkgs)
        sops
        age
        ;
    };
    sops = {
      defaultSopsFile = lib.mkIf (config.meta.secretsFile != null) config.meta.secretsFile;
      defaultSopsFormat = lib.mkDefault "yaml";
      age = {
        keyFile = lib.mkDefault "/var/lib/sops-nix/keys.txt";
      };
    };
  };
}
