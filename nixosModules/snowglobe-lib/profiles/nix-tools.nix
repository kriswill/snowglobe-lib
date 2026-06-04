{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-lib.profiles.nix-tools;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-lib.profiles.nix-tools = {
    enable = lib.mkEnableOption "Snowglobe-Lib's choice of tools for development with nix";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      nix-output-monitor.enable = slib.setDefault true;
      nix-index-database = {
        enable = slib.setDefault true;
        comma.enable = slib.setDefault true;
      };
      nix-fast-build.enable = slib.setDefault true;
      nvd.enable = slib.setDefault true;
      nh.enable = slib.setDefault true;
      direnv.enable = slib.setDefault true;
    };

    environment.systemPackages = builtins.attrValues {
      inherit (pkgs)
        nurl
        nix-prefetch-git
        deadnix
        nixpkgs-hammering
        statix
        nix-init
        nix-update
        nixpkgs-review
        nixfmt
        ;
    };
  };
}
