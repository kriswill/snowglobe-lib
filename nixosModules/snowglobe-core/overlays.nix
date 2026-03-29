{
  outputs,
  lib,
  config,
  ...
}:
let
  overlays = outputs.overlays;
  cfg = config.snowglobe-core.overlays;
in
{
  options.snowglobe-core.overlays = {
    awww-git.enable = lib.mkEnableOption "rolling release for awww";
    nh-git.enable = lib.mkEnableOption "rolling release for nix helper";
    disko-git.enable = lib.mkEnableOption "rolling release for disko";
    ghostty-git.enable = lib.mkEnableOption "rolling release for ghostty";
    manga-tui-git.enable = lib.mkEnableOption "rolling release for manga-tui";
    niri-git.enable = lib.mkEnableOption "rolling release for niri";
    nixos-anywhere-git.enable = lib.mkEnableOption "rolling release for nixos-anywhere";
    prismlauncher-git.enable = lib.mkEnableOption "rolling release for prismlauncher";
    rmpc-git.enable = lib.mkEnableOption "rolling release for rmpc";
    yazi-git.enable = lib.mkEnableOption "rolling release for yazi";
    zsh-syntax-highlighting-fix.enable = lib.mkEnableOption ''
      a patch to allow zsh-syntax-highlighting package to be installed via environment.systemPackages
      and will ensure that plugins correctly end up in /run/current-system/sw/share/zsh/plugins.
    '';
  };

  config = {
    nixpkgs.overlays =
      let
        # imported regardless of snowglobe-core.enable, so just pray there are no conflicts
        requiredOverlays = builtins.attrValues {
          inherit (overlays)
            packages
            packaged-configs
            helper-scripts
            ;
        };
        optionalOverlays =
          [ ]
          ++ lib.remove null (
            lib.forEach (builtins.attrNames overlays) (
              overlay: if (cfg ? ${overlay} && cfg.${overlay}.enable) then overlays.${overlay} else null
            )
          );
      in
      optionalOverlays ++ requiredOverlays;
  };
}
