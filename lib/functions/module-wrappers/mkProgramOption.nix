{ lib }:
{
  pkgs,
  programName,
  packageName ? programName,
  description ? null,
  excludedOptions ? [ ], # options to exclude from creation, used to patch program options from nixpkgs
  extraPackageArgs ? { },
  extraOptions ? { },
}:
let
  isIncluded = option: (!builtins.elem option excludedOptions);
in
(
  if isIncluded "enable" then
    {
      enable = (
        lib.mkEnableOption (programName + lib.optionalString (description != null) ", a " + description)
      );
    }
  else
    { }
)
// (
  if isIncluded "package" then
    {
      package = lib.mkPackageOption pkgs packageName extraPackageArgs;
    }
  else
    { }
)
// (
  if isIncluded "installGlobally" then
    {
      installGlobally = lib.mkOption {
        description = ''
          enable ${programName} globally for all users on this system.
        '';
        type = lib.types.bool;
        default = true;
      };
    }
  else
    { }
)
// (
  if isIncluded "installForUsers" then
    {
      installForUsers = lib.mkOption {
        description = ''
          List of users to install the program, defaults to [ ] if installGlobally is enabled
        '';
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    }
  else
    { }
)
// {
  userPackages = lib.mkOption {
    description = "Configuration to deploy custom package builds of a program to targetted users";
    type = lib.types.attrsOf lib.types.package;
    default = { };
  };
}
// extraOptions
