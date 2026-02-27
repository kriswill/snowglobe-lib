{
  outputs,
  lib,
  config,
  ...
}:
let
  overlays = outputs.overlays;
  cfg = config.earthgman.overlays;
in
{
  options.earthgman.overlays = {
    awww-git.enable = lib.mkEnableOption "rolling release for awww";
    nh-git.enable = lib.mkEnableOption "rolling release for nix helper";
    niri-git.enable = lib.mkEnableOption "rolling release for niri";
    prismlauncher-git.enable = lib.mkEnableOption "rolling release for prismlauncher";
    yazi-git.enable = lib.mkEnableOption "rolling release for yazi";
    zsh-syntax-highlighting-fix.enable = lib.mkEnableOption ''
      a patch to allow zsh-syntax-highlighting package to be installed via environment.systemPackages
      and will ensure that plugins correctly end up in /run/current-system/sw/share/zsh/plugins.
    '';
  };

  config = {
    nixpkgs.overlays =
      let
        # imported regardless of earthgman.enable, so just pray there are no conflicts
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
