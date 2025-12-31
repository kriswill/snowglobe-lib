{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.gman.zsh.enable = lib.mkEnableOption "gman's zsh configuration";

  config = lib.mkIf config.gman.zsh.enable {
    environment.systemPackages = [ pkgs.starship ];
    programs.zsh = {
      enable = lib.mkDefault true;
      enableCompletion = lib.mkDefault true;
      syntaxHighlighting.enable = lib.mkDefault true;
      autosuggestions.enable = lib.mkDefault true;
      shellAliases = import ../../mixins/shell-aliases.nix { inherit lib config; };

      promptInit = ''
        setopt autocd
      '';
    };
  };
}
