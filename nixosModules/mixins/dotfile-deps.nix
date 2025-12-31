# dependencies of my personal dotfiles
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.dotfile-deps;
in
{
  options.gman.dotfile-deps = {
    enable = lib.mkEnableOption "the services and programs that my personal dotfiles depend upon";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (config.meta.desktop == "niri") {
        programs.niri = {
          enable = true;
        };
      })
      {
        # use pass and gnupg for secrets not gnome-keyring
        services.gnome.gnome-keyring.enable = false;

        # install needed xdg-portals
        xdg.portal = {
          wlr.enable = true;
          extraPortals = builtins.attrValues {
            inherit (pkgs)
              # ensure gtk portal is installed
              xdg-desktop-portal-gtk
              xdg-desktop-portal-termfilechooser
              ;
          };
        };

        # custom service patch for kde portal
        # services.xdg-desktop-portal-kde.enable = true;

        environment.systemPackages = builtins.attrValues (
          {
            inherit (pkgs)
              libnotify
              wl-clipboard
              grim
              slurp
              swayidle
              coreutils-full
              findutils
              xdg-utils
              xdg-user-dirs

              star-pixel-icons
              ;
          }
          // {
            # gets information regarding xwayland windows
            inherit (pkgs.xorg) xwininfo;
          }
        );

        fonts.packages = builtins.attrValues (
          {
            inherit (pkgs)
              pixel-code
              "8-bit-operator-font"
              omori-font
              noto-fonts
              ;
          }
          // {
            inherit (pkgs.nerd-fonts)
              meslo-lg
              jetbrains-mono
              ;
          }
        );

        gman = {
          nix-development.enable = true;
          # custom per-user instance of mpd for accessing that users Music directory
          mpd-user.enable = true;
        };

        programs = {
          # optional programs
          cava.enable = lib.mkDefault true;
          cmatrix.enable = lib.mkDefault true;
          cbonsai.enable = lib.mkDefault true;
          sl.enable = lib.mkDefault true;
          firefox.enable = lib.mkDefault true;
          hstr.enable = lib.mkDefault true;
          pipes.enable = lib.mkDefault true;
          qutebrowser.enable = lib.mkDefault true;

          # these will give stock configurations for the programs by default.
          # You can then imperatively configure or set the .package option to your own wrapped nix derivation.
          neovim-custom.enable = lib.mkDefault true;
          yazi-custom.enable = lib.mkDefault true;

          rmpc.enable = lib.mkDefault true;
          yt-dlp.enable = lib.mkDefault true;
          vlc.enable = lib.mkDefault true;
          # disable alacritty because it is enabled in niri config
          alacritty.enable = lib.mkOverride 899 false;
          kitty.enable = lib.mkDefault true;
          gnome-calculator.enable = lib.mkDefault true;
          # gtk themer
          nwg-look.enable = lib.mkDefault true;
          # default pdf viewer
          evince.enable = lib.mkDefault true;
          # default image viewer
          gthumb.enable = lib.mkDefault true;
          # default graphical file manager
          nautilus.enable = true;

          # core dependencies
          swaylock.enable = true;
          selectdefaultapplication.enable = true;
          rofi.enable = true;
          password-store.enable = true;
          # use git auth with pass
          pass-git-helper.enable = true;
          gnupg.agent = {
            enable = true;
            enableSSHSupport = true;
          };
          lynx.enable = true;
          eza.enable = true;
          dconf.enable = true;
          # suckless/simple terminal
          st.enable = true;
          # setting timers
          gnome-clocks.enable = true;
          # pipewire control dashboard
          pwvucontrol.enable = true;

          # status bar for wayland
          waybar.enable = true;
        };

        services = {
          # tray applet for networkmanager
          nm-applet.enable = lib.mkDefault true;

          # idle daemon
          swayidle = {
            enable = lib.mkDefault true;
            flags = [
              "-w"
              "-d"
            ];
          };

          # wayland wallpaper daemon
          awww = {
            enable = true;
            flags = lib.mkDefault [
              "-f"
              "argb"
            ];
          };
        };
      }
    ]
  );
}
