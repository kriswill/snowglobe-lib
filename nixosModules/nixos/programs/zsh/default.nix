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
    extraOptions = {
      setAsDefaultShell = lib.mkEnableOption "zsh as the default shell";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        users.defaultUserShell = lib.mkIf (cfg.setAsDefaultShell) cfg.package;
        environment.systemPackages =
          [ ]
          ++ lib.optionals (cfg.syntaxHighlighting.enable) [
            pkgs.zsh-syntax-highlighting
          ]
          ++ lib.optionals (cfg.autosuggestions.enable) [
            pkgs.zsh-autosuggestions
          ];
        users.users = lib.mkIf cfg.setAsDefaultShell (
          lib.genAttrs cfg.installForUsers (username: {
            shell = "${cfg.userPackages.${username}}/bin/zsh";
          })
        );
      };
    }
  );
}
