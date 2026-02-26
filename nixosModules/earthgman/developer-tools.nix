{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.developer-tools;
in
{
  options.earthgman.developer-tools = {
    enable = lib.mkEnableOption "EarthGman's choice of tools for development with nix";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      nix-output-monitor.enable = true;
      nix-fast-build.enable = true;
      nvd.enable = lib.setDefault true;
      nh.enable = true;
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
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
