{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "tmux-custom";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "custom program option for yazi, allowing for custom wrapped yazi configurations";
    programName = program-name;
    packageName = "tmux";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    programs.tmux.enable = lib.mkOverride 0 false;
    environment.systemPackages = [
      cfg.package
    ];
  };
}
