{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.programs.neovim-custom;
in
{
  options.programs.neovim-custom = {
    enable = lib.mkEnableOption "fully configured custom neovim package";

    package = lib.mkOption {
      description = "package for your configured neovim";
      type = lib.types.package;
      default = pkgs.gman.nvim;
    };

    defaultEditor = lib.mkEnableOption "neovim as the default editor";

    viAlias = lib.mkEnableOption "custom neovim vi alias";
    vimAlias = lib.mkEnableOption "custom neovim vim alias";
  };

  config = lib.mkIf cfg.enable {
    environment.variables.EDITOR = lib.mkIf cfg.defaultEditor (lib.mkForce "nvim");

    programs = {
      vim.enable = lib.mkIf (cfg.vimAlias) (lib.mkForce false);
      neovim.enable = lib.mkForce false;
    };

    environment.systemPackages = [
      cfg.package
    ]
    ++ lib.optionals cfg.viAlias [
      (pkgs.symlinkJoin {
        name = "vi";
        paths = [ cfg.package ];

        postBuild = ''
          rm -f $out/bin/vi
          ln -s $out/bin/nvim $out/bin/vi
        '';
      })
    ]
    ++ lib.optionals cfg.vimAlias [
      (pkgs.symlinkJoin {
        name = "vim";
        paths = [ cfg.package ];

        postBuild = ''
          rm -f $out/bin/vim
          ln -s $out/bin/nvim $out/bin/vim
        '';
      })
    ];
  };
}
