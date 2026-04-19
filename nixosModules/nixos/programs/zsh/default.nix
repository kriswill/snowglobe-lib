{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "zsh";
  cfg = config.programs.${programName};
in
{
  options.programs.zsh = lib.mkProgramOption {
    inherit programName pkgs;
    excludedOptions = [
      "enable"
    ];
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        environment.systemPackages =
          [ ]
          ++ lib.optionals (cfg.syntaxHighlighting.enable) [
            pkgs.zsh-syntax-highlighting
          ]
          ++ lib.optionals (cfg.autosuggestions.enable) [
            pkgs.zsh-autosuggestions
          ];
      };
    }
  );
}
