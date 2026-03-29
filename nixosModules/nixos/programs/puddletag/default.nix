{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "puddletag";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "mp3/audio file tagger, open source alternative to mp3tag for windows";
    programName = programName;
    packageName = programName;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
    }
  );
}
