# configure programs and their respective packages
# install specific packages for root
{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
  cfg = config.snowglobe-core.program-configs;
in
{
  options.snowglobe-core.program-configs.enable = lib.mkEnableOption ''
    Snowglobe-Core's custom program configurations and package modifications
  '';
  config = lib.mkIf cfg.enable {
    programs = {
      # better discord
      discord.package = slib.setDefault pkgs.vesktop;
      # hardened firefox
      firefox.package = slib.setDefault pkgs.librewolf;
      # password store with otp support
      password-store.package = slib.setDefault (pkgs.pass.withExtensions (exts: [ exts.pass-otp ]));
      # bleeding edge libreoffice
      libreoffice.package = slib.setDefault pkgs.libreoffice-fresh;
      # no spyware chromium
      chromium.package = slib.setDefault pkgs.ungoogled-chromium;
      # alias pavucontrol to pwvucontrol
      pwvucontrol.pavucontrolAlias = slib.setDefault true;

      neovim = {
        viAlias = slib.setDefault true;
        vimAlias = slib.setDefault true;
      };

      nh.flake = slib.setDefault "/etc/nixos";

      zsh = {
        autosuggestions.enable = slib.setDefault true;
        syntaxHighlighting.enable = slib.setDefault true;
      };

      # make direnv be not annoying
      # direnv = {
      #   silent = slib.setDefault true;
      # };
    };
    environment.variables = lib.mkIf config.programs.direnv.enable {
      DIRENV_WARN_TIMEOUT = slib.setDefault 0;
    };

    # always use wayland for sddm
    services.displayManager.sddm.wayland.enable = slib.setDefault true;
  };
}
