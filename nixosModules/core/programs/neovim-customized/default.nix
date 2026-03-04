# incorporating a custom neovim package into programs.neovim is not very easy
# so just use this module as a scapegoat
# TODO find some way to nuke and replace programs.neovim with this
{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "neovim-customized";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "customized module for importing packaged neovim configs.";
    programName = programName;
    packageName = "neovim";
    inherit pkgs;
    extraOptions = {
      defaultEditor = lib.mkEnableOption "custom neovim as your default editor";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        # force default neovim off
        programs.neovim.enable = lib.mkForce false;
        environment.variables.EDITOR = lib.mkIf cfg.defaultEditor "nvim";
      };
    }
  );
}
