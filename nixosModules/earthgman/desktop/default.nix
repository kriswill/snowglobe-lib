{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.desktop;
in
{
  imports = lib.autoImport ./. { };

  options.earthgman.desktop.enable = lib.mkEnableOption "EarthGman's modules for systems with a desktop environment";

  config = lib.mkIf cfg.enable {
    earthgman = {
      display-manager.enable = lib.setDefault true;
      pipewire-config.enable = lib.setDefault true;
      printing-config.enable = lib.setDefault true;

      desktop =
        let
          activeDesktop = config.system.desktop;
        in
        {
          niri.enable = (activeDesktop == "niri");
        };
    };

    # add a virtual camera for obs
    boot.extraModulePackages = [
      config.boot.kernelPackages.v4l2loopback
    ];

    # allow imperative installation for sandboxed applications
    services.flatpak.enable = lib.setDefault true;

    programs = {
      # frontend to flatpak
      gnome-software.enable = lib.setDefault config.services.flatpak.enable;
      # gtk and gnome software database
      dconf.enable = lib.setDefault true;
      # frontend to manage dconf
      dconf-editor.enable = lib.setDefault config.programs.dconf.enable;
      # web browser
      firefox.enable = lib.setDefault true;
    };

    environment.systemPackages = builtins.attrValues {
      inherit (pkgs)
        # ensure a fully functional cursor and icon theme are installed
        # adwaita-cursors
        adwaita-icon-theme

        # extra stuff
        xdg-utils
        xdg-user-dirs
        ;
    };

    # free fonts that support many languges and locales
    fonts.packages = [ pkgs.noto-fonts ];

    # configures the xdg-desktop-portal, allowing standardized interprocess communication between applications
    # EX: opening a link from some app in the default browser
    xdg.portal = {
      enable = lib.setDefault true;
      # all xdg-open commands will use the portal configuration by default
      xdgOpenUsePortal = lib.setDefault true;
    };

    # allows configuration for underprivileged users interacting with privileged process
    # ex calling reboot or poweroff without sudo
    # desktop modules install a unique polkit-agent, which allows the session to communicate with polkit
    security.polkit.enable = lib.setDefault true;

    hardware.graphics = {
      enable = true;
      enable32Bit = lib.mkIf ((builtins.substring 0 3 config.nixpkgs.hostPlatform.system) == "x86") (
        lib.setDefault true
      );
    };
  };
}
