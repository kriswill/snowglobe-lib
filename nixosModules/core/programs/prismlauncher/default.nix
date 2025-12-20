{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "prismlauncher";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "comphrensive 3rd party minecraft launcher";
    programName = program-name;
    packageName = program-name;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      # java binaries are added to /run/current-system/sw/bin
      # otherwise prismlauncher will hardcode the binary paths to the /nix/store and will have to be changed every flake update
      # java 8 for legacy minecraft versions
      pkgs.jre8
      # latest java for modern versions
      pkgs.jre
    ];
  };
}
