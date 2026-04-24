{
  outputs,
  lib,
  config,
  ...
}:
let
  overlays = outputs.overlays;
  cfg = config.snowglobe-lib.overlays;
  overlayNames = builtins.attrNames overlays;
  slib = import ../../lib/functions/module-wrappers { inherit lib; };

  getRollingReleaseOverlays =
    overlayNames:
    (lib.remove null (
      lib.forEach (overlayNames) (
        name:
        let
          splitName = lib.splitString "-" "${name}";
          numWords = builtins.length splitName;
          lastWordIndex = numWords - 1;
          lastWord = builtins.elemAt splitName lastWordIndex;
        in
        if ((lastWord) == "git") then "${name}" else null
      )
    ));

  buildProgramName =
    splitWordsList: wordsRemaining:
    let
      splitWordsLength = builtins.length splitWordsList;
      currentWord = builtins.elemAt splitWordsList (splitWordsLength - wordsRemaining);
    in
    if (wordsRemaining == 1) then
      "${currentWord}"
    else
      "${currentWord}" + "-" + "${buildProgramName splitWordsList (wordsRemaining - 1)}";
in
{
  options.snowglobe-lib.overlays =
    # assume rolling release overlays are named as ${program}-git
    lib.genAttrs (getRollingReleaseOverlays overlayNames) (
      name:
      let
        splitName = lib.splitString "-" "${name}";
        numWords = builtins.length splitName;
        programName = "${buildProgramName splitName (numWords - 1)}";
      in
      {
        enable = lib.mkEnableOption "rolling release for ${programName}";
      }
    )
    // {
      zsh-syntax-highlighting-fix.enable = lib.mkEnableOption ''
        a patch to allow zsh-syntax-highlighting package to be installed via environment.systemPackages
        and will ensure that plugins correctly end up in /run/current-system/sw/share/zsh/plugins.
      '';
    };

  config = {
    nixpkgs.overlays =
      let
        # imported regardless of snowglobe-lib.enable, so just pray there are no conflicts
        requiredOverlays = builtins.attrValues {
          inherit (overlays)
            packages
            ;
        };
        optionalOverlays =
          [ ]
          ++ lib.remove null (
            lib.forEach (overlayNames) (
              overlay: if (cfg ? ${overlay} && cfg.${overlay}.enable) then overlays.${overlay} else null
            )
          );
      in
      optionalOverlays ++ requiredOverlays;

    # automatically enable overlays if the main module set is enabled
    snowglobe-lib.overlays = lib.mkIf config.snowglobe-lib.enable (
      # rolling releases
      lib.genAttrs (getRollingReleaseOverlays overlayNames) (name: {
        enable = slib.setDefault true;
      })
      # other optional overlays
      // {
        zsh-syntax-highlighting-fix.enable = slib.setDefault true;
      }
    );
  };
}
