{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.nix-development;
in
{
  options.gman.nix-development.enable = lib.mkEnableOption "gman's nix development suite";

  config = lib.mkIf cfg.enable {
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

    # patch direnv to not be annoying
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
    };
    environment.variables = {
      DIRENV_WARN_TIMEOUT = 0;
    };
  };
}
