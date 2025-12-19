# not to be interpreted as "desktop PC" but module for any machine that has a desktop environment
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.desktop;

  defaultSession =
    if (config.meta.desktop == "hyprland") then
      "hyprland-uwsm"
    else if (config.meta.desktop == "sway") then
      "sway-uwsm"
    else
      config.meta.desktop;
in
{
  imports = lib.autoImport ./.;

  options.gman.desktop.enable = lib.mkEnableOption "gman's configuration for hosts with a desktop environment";

  config = lib.mkIf cfg.enable {
    # configuration revelent for desktop
    gman = {
      # sound / screen capture server
      pipewire.enable = lib.mkDefault true;

      # common printing configuration
      printing.enable = lib.mkDefault true;

      # which desktop to enable
      # multiple desktops can be enabled at once but it is not recommended nor supported
      desktop =
        let
          activeDesktop = config.meta.desktop;
        in
        {
          # friendship ended with gnome
          # gnome.enable = (activeDesktop == "gnome");
          plasma.enable = (activeDesktop == "plasma");
          sway.enable = (activeDesktop == "sway");
          hyprland.enable = (activeDesktop == "hyprland");
          niri.enable = (activeDesktop == "niri");
        };

      # installs various hardware monitoring and configuration tools
      hardware-tools.enable = lib.mkDefault true;
    };

    # stock nixos modules
    boot = {
      extraModulePackages = [
        # adds a device for obs virtual camera
        config.boot.kernelPackages.v4l2loopback
      ];
    };

    # setup bluetooth
    hardware.bluetooth.enable = true;
    # gtk configuration GUI and tray applet
    services.blueman.enable = lib.mkDefault true;

    environment.systemPackages =
      builtins.attrValues {
        inherit (pkgs)
          # # install some icons
          adwaita-icon-theme
          # install some cursors
          bibata-cursors
          # backport of libadwaita to gtk3
          # required for many legacy gtk3 apps to respect custom color schemes
          adw-gtk3

          # various helper software
          xdg-user-dirs
          xdg-utils
          dex
          desktop-file-utils
          ;
      }
      ++ (builtins.attrValues {
        inherit (pkgs.kdePackages)
          breeze
          ;
      });

    # install some fonts (many are included by default)
    fonts.packages = builtins.attrValues {
      # Make sure nerd font is installed
      inherit (pkgs.nerd-fonts)
        meslo-lg
        ;
    };

    # kind of redundant, but good to have.
    hardware.graphics = {
      enable = true;
      enable32Bit = lib.mkDefault true;
    };

    services = {
      # set the determined default session for the display manager
      displayManager = {
        inherit defaultSession;
      };
      # mounting network drives in file managers
      gvfs.enable = lib.mkDefault true;
    };

    services.flatpak.enable = lib.mkDefault true;
    programs = {
      # gtk frontend to flatpak
      gnome-software.enable = lib.mkDefault config.services.flatpak.enable;
      # overcomplicated gtk settings database
      dconf.enable = lib.mkDefault true;
      dconf-editor.enable = lib.mkDefault config.programs.dconf.enable;
      # default browser
      firefox.enable = lib.mkDefault true;
    };

    # use sddm as default display manager, will change to gdm if gnome is the desktop
    # my sddm config
    gman.sddm.enable = lib.mkDefault true;

    # ensure xserver configuration is applied
    services.xserver = {
      enable = lib.mkDefault true;
      excludePackages = builtins.attrValues {
        inherit (pkgs)
          xterm
          ;
      };
    };

    # configures the xdg-desktop-portal, allowing standardized interprocess communication between applications
    # EX: opening a link from some app in the default browser
    xdg.portal = {
      enable = lib.mkDefault true;
      # all xdg-open commands will use the portal configuration by default
      xdgOpenUsePortal = lib.mkDefault true;
    };

    # allows configuration for underprivileged users interacting with privileged process
    # ex calling reboot or poweroff without sudo
    # desktop modules install a unique polkit-agent, which allows the session to communicate with polkit
    security.polkit.enable = lib.mkDefault true;

    qt = {
      enable = lib.mkDefault true;
      platformTheme = lib.mkDefault null;
      # utilize kvantum for to style QT for window managers
      # it is better than qt6ct in my opinion
      style = lib.mkDefault "kvantum";
    };
  };
}
