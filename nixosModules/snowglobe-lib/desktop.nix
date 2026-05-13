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
  options.snowglobe-lib.desktop.enable = lib.mkEnableOption "Snowglobe-Lib's modules for systems with a desktop environment";

  config = lib.mkIf cfg.enable {
    snowglobe-lib = {
      # TODO maybe redo this module
      # uses sddm with astronaut qt6 theme by default
      # can also be set to use "ly"
      display-manager.enable = slib.setDefault true;
    };

    # make sure all parts of the networkmanager GUI work
    networking.networkmanager.plugins = builtins.attrValues {
      inherit (pkgs)
        networkmanager-openvpn
        ;
    };

    # TODO nixos-facter?
    # enable bluetooth
    hardware.bluetooth.enable = slib.setDefault true;
    # GTK gui for bluetooth
    services.blueman.enable = slib.setDefault true;
    # imperative sandboxed application management service
    # add a virtual camera for obs
    boot.extraModulePackages = [
      config.boot.kernelPackages.v4l2loopback
    ];

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
    # flatpak frontend of choice for (kde module will ensure discover is used instead)
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
      # gtk and gnome software database
      dconf.enable = slib.setDefault true;
      # frontend to manage dconf
      dconf-editor.enable = slib.setDefault config.programs.dconf.enable;
      # web browser
      firefox.enable = slib.setDefault true;
    };

    environment.systemPackages = builtins.attrValues {
      inherit (pkgs)
        # ensure a fully functional cursor and icon theme are installed
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
      enable = slib.setDefault true;
      # all xdg-open commands will use the portal configuration by default
      xdgOpenUsePortal = slib.setDefault true;
    };

    # allows configuration for underprivileged users interacting with privileged process
    # ex calling reboot or poweroff without sudo
    # desktop modules install a unique polkit-agent, which allows the session to communicate with polkit
    security.polkit.enable = slib.setDefault true;

    hardware.graphics = {
      enable = true;
      # 32 bit support doesn't exist on other arches
      enable32Bit = lib.mkIf ((builtins.substring 0 3 config.nixpkgs.hostPlatform.system) == "x86") (
        slib.setDefault true
      );
    };
  };
}
