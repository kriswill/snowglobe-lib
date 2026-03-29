{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "foot";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    inherit pkgs;
    description = "A simple terminal emulator for X and Wayland";
    programName = programName;
    packageName = programName;
    extraOptions = {
      systemd.enable = lib.mkOption {
        description = "Whether to enable the systemd unit for foot --server";
        type = lib.types.bool;
        default = true;
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        systemd.packages = lib.mkIf cfg.systemd.enable [ cfg.package ];
      };
    }
  );
}
