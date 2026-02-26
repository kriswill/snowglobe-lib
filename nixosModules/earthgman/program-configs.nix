# install configs from https://git.earthgman.dev/earthgman/dotfiles for the root user
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.program-configs;
in
{

  options.earthgman.program-configs.enable = lib.mkEnableOption ''
    EarthGman's custom program configurations and package modifications
  '';
  config = lib.mkIf cfg.enable {
    programs = {
      #   # better discord
      discord.package = lib.setDefault pkgs.vesktop;
      #   # hardened firefox
      firefox.package = lib.setDefault pkgs.librewolf;
      #   # password store with otp support
      password-store.package = lib.setDefault (pkgs.pass.withExtensions (exts: [ exts.pass-otp ]));

      nh.flake = lib.setDefault "/etc/nixos";

      neovim-customized = {
        package = lib.setDefault pkgs.earthgman.neovim;
        defaultEditor = lib.setDefault true;
      };

      zsh = {
        installForUsers = lib.setDefault [ "root" ];
        userPackages.root = lib.setDefault pkgs.earthgman.zsh;
        setAsDefaultShell = lib.setDefault true;
        syntaxHighlighting.enable = lib.setDefault true;
        autosuggestions.enable = lib.setDefault true;
      };

      tmux = {
        installForUsers = lib.setDefault [ "root" ];
        userPackages.root = lib.setDefault pkgs.earthgman.tmux;
      };

      yazi = {
        installForUsers = lib.setDefault [ "root" ];
        userPackages.root = lib.setDefault pkgs.earthgman.yazi;
      };

      # make direnv be not annoying
      direnv = {
        silent = true;
      };
    };
    environment.variables = lib.mkIf config.programs.direnv.enable {
      DIRENV_WARN_TIMEOUT = lib.setDefault 0;
    };
  };

}
