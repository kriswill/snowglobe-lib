{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-lib.desktop;
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-lib.desktop = {
    enable = lib.mkEnableOption "Snowglobe-Lib's modules for systems with a desktop environment";
    installWaylandDeps = lib.mkEnableOption "wayland tools for desktop.";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf cfg.installWaylandDeps {
        environment.systemPackages = builtins.attrValues {
          inherit (pkgs)
            # provide wlr-randr to system path
            wlr-randr
            ;
        };

        xdg.portal.wlr.enable = slib.setDefault true;

        programs = {
          # screenshot & clipboard tools
          grim.enable = slib.setDefault true;
          slurp.enable = slib.setDefault true;
          wl-clipboard.enable = slib.setDefault true;
          # screen power manager
          wlopm.enable = slib.setDefault true;
          # notification daemon for wayland
          swaync = {
            enable = slib.setDefault true;
            systemd.enable = slib.setDefault true;
          };
          # wayland lockscreen that works with pam-gnupg
          swaylock.enable = slib.setDefault true;
        };

        environment = {
          sessionVariables = {
            # force electron apps to run using wayland
            NIXOS_OZONE_WL = slib.setDefault "1";
            # fix blank screens with java applications running under xwayland-satellite
            _JAVA_AWT_WM_NONREPARENTING = slib.setDefault "1";
          };
        };
      })
      {
        # add a lightweight display-manager
        services.displayManager.ly.enable = slib.setDefault true;
        # ensure that polkit is enabled
        security.polkit.enable = true;
        # add some vpn plugins to network manager
        networking.networkmanager.plugins = builtins.attrValues {
          inherit (pkgs)
            networkmanager-openvpn
            ;
        };

        # TODO detect if bluetooth hardware exists
        # enable bluetooth
        hardware.bluetooth.enable = slib.setDefault true;
        # GTK gui for bluetooth
        services.blueman.enable = slib.setDefault config.hardware.bluetooth.enable;

        # TODO does not work under UWSM due to UWSM 26 not passing XDG_SESSION_ID to dbus automatically
        # This cant be solved from this project without the user adding a hackfix to the desktop's config in the home directory
        # security.soteria.enable = slib.setDefault true;

        # instead opt to use a hacked together systemd unit for polkit_gnome
        services.polkit-gnome.enable = slib.setDefault true;

        # use pipewire for the sound server
        security.rtkit.enable = slib.setDefault true; # hands out realtime scheduling priority to user processes on demand. Improves performance of pulse
        services.pipewire = {
          # enables alsa, pulseaudio, and jack support by default
          enable = slib.setDefault true;
          alsa.enable = slib.setDefault true;
          alsa.support32Bit = slib.setDefault true;
          pulse.enable = slib.setDefault true;
          jack.enable = slib.setDefault true;
        };

        # configure flatpak
        services.flatpak.enable = slib.setDefault true;
        # flatpak frontend of choice
        programs.gnome-software.enable = slib.setDefault true;
        # service from nixos wiki to automatically add flathub
        systemd.services.flatpak-repo = {
          wantedBy = [ "multi-user.target" ];
          path = [ config.services.flatpak.package ];
          script = ''
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
          '';
        };

        programs = {
          # control applet for networkmanager
          networkmanagerapplet.enable = slib.setDefault true;
          # gtk and gnome software database
          dconf.enable = slib.setDefault true;
          # frontend to manage dconf
          dconf-editor.enable = slib.setDefault config.programs.dconf.enable;
          # web browser
          firefox.enable = slib.setDefault true;
          # file manager
          nautilus.enable = slib.setDefault true;
          # lightweight notepad clone
          mousepad.enable = slib.setDefault true;
          # volume control for pipewire-pulse
          pwvucontrol.enable = slib.setDefault true;
          # calculator app
          gnome-calculator.enable = slib.setDefault true;
          # low battery notifier for laptops
          batsignal = {
            enable = slib.setDefault true;
            systemd.enable = slib.setDefault true;
          };
        };

        environment.systemPackages = builtins.attrValues {
          inherit (pkgs)
            # ensure a fully functional cursor and icon theme are installed
            adwaita-icon-theme
            # xdg utilities
            xdg-utils
            xdg-user-dirs
            # notification api
            libnotify
            ;
        };

        fonts.packages = [
          # free fonts that support many locales
          pkgs.noto-fonts
          # ensure a nerd font is installed
          pkgs.nerd-fonts.meslo-lg
        ];

        # configures the xdg-desktop-portal, allowing standardized interprocess communication between applications
        # EX: opening a link from some app in the default browser
        xdg.portal = {
          enable = slib.setDefault true;
          # all xdg-open commands will use the portal configuration by default
          xdgOpenUsePortal = slib.setDefault true;
          extraPortals = builtins.attrValues {
            inherit (pkgs)
              # popular portal for window manager environments
              xdg-desktop-portal-gtk
              # allow the user to configure a terminal filechooser (like yazi)
              xdg-desktop-portal-termfilechooser
              ;
          };
        };

        hardware.graphics = {
          enable = true;
          # 32 bit support doesn't exist on other arches
          enable32Bit = lib.mkIf ((builtins.substring 0 3 config.nixpkgs.hostPlatform.system) == "x86") (
            slib.setDefault true
          );
        };
      }
    ]
  );
}
