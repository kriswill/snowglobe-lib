{ lib }:
{
  pkgs,
  programName,
  packageName ? programName,
  description ? null,
  extraPackageArgs ? { },
}:
{
  enable = lib.mkEnableOption (
    programName + " " + lib.optionalString (description != null) description
  );
  package = lib.mkPackageOption pkgs packageName extraPackageArgs;
}
