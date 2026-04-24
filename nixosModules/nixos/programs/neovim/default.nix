{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "neovim";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    description = "customized module for importing packaged neovim configs.";
    programName = programName;
    inherit pkgs;
    extraOptions = {
      defaultEditor = lib.mkEnableOption "Neovim as your default editor";
      viAlias = lib.mkEnableOption "vi aliased to nvim";
      vimAlias = lib.mkEnableOption "vim aliased to nvim";
    };
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
      extraModules = {
        environment = {
          sessionVariables.EDITOR = lib.mkIf (cfg.defaultEditor) (lib.mkForce "nvim");
          systemPackages =
            let
              viAlias =
                if (cfg.viAlias) then
                  slib.mkProgramAlias {
                    program = "nvim";
                    alias = "vi";
                    package = cfg.package;
                    inherit pkgs;
                  }
                else
                  null;

              vimAlias =
                if (cfg.vimAlias) then
                  slib.mkProgramAlias {
                    program = "nvim";
                    alias = "vim";
                    package = cfg.package;
                    inherit pkgs;
                  }
                else
                  null;
            in
            [ ] ++ lib.optionals (viAlias != null) [ viAlias ] ++ lib.optionals (vimAlias != null) [ vimAlias ];
        };
      };
    }
  );
}
