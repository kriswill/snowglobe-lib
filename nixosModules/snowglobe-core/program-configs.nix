# configure programs and their respective packages
# install specific packages for root
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-core.program-configs;
in
{
  options.snowglobe-core.program-configs.enable = lib.mkEnableOption ''
    Snowglobe-Core's custom program configurations and package modifications
  '';
  config = lib.mkIf cfg.enable {
    programs = {
      # better discord
      discord.package = lib.setDefault pkgs.vesktop;
      # hardened firefox
      firefox.package = lib.setDefault pkgs.librewolf;
      # password store with otp support
      password-store.package = lib.setDefault (pkgs.pass.withExtensions (exts: [ exts.pass-otp ]));
      # bleeding edge libreoffice
      libreoffice.package = lib.setDefault pkgs.libreoffice-fresh;
      # no spyware chromium
      chromium.package = lib.setDefault pkgs.ungoogled-chromium;
      # alias pavucontrol to pwvucontrol
      pwvucontrol.pavucontrolAlias = lib.setDefault true;

      neovim = {
        viAlias = lib.setDefault true;
        vimAlias = lib.setDefault true;
      };

      nh.flake = lib.setDefault "/etc/nixos";

      zsh = {
        autosuggestions.enable = lib.setDefault true;
        syntaxHighlighting.enable = lib.setDefault true;
      };

      # make direnv be not annoying
      # direnv = {
      #   silent = lib.setDefault true;
      # };
    };
    environment.variables = lib.mkIf config.programs.direnv.enable {
      DIRENV_WARN_TIMEOUT = lib.setDefault 0;
    };

    # always use wayland for sddm
    services.displayManager.sddm.wayland.enable = lib.setDefault true;
  };
}
