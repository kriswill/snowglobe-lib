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
      {
        # setup pam to allow decrypting of gpg key on login and through swaylock
        security.pam.services = {
          swaylock.gnupg.enable = true;
          login.gnupg = {
            enable = lib.mkDefault true;
            storeOnly = lib.mkDefault true;
          };
        };
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

        environment.systemPackages = builtins.attrValues ({
          inherit (pkgs)
            libnotify
            brightnessctl
            wl-clipboard
            grim
            slurp
            swayidle
            coreutils-full
            findutils
            xdg-utils
            xdg-user-dirs

            star-pixel-icons
            xwininfo
            ;
        });

        fonts.packages = builtins.attrValues (
          {
            inherit (pkgs)
              pixel-code
              _8-bit-operator-font
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
          # custom per-user instance of mpd for accessing the users ~/Music directory
          mpd-user.enable = true;
        };

        programs = {
          # core dependencies
          swaylock.enable = true;
          selectdefaultapplication.enable = true;
          bat.enable = true;
          rofi.enable = true;
          # remove fuzzel from niri configuration in favor of rofi
          fuzzel.enable = lib.mkOverride 899 false;
          fzf.enable = lib.mkDefault true;
          password-store = {
            enable = true;
            package = lib.mkDefault (pkgs.pass.withExtensions (exts: [ exts.pass-otp ]));
          };
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

          # optional programs
          starship.enable = lib.mkDefault true;
          cava.enable = lib.mkDefault true;
          cmatrix.enable = lib.mkDefault true;
          cbonsai.enable = lib.mkDefault true;
          neomutt.enable = lib.mkDefault true;
          sl.enable = lib.mkDefault true;
          firefox.enable = lib.mkDefault true;
          hstr.enable = lib.mkDefault true;
          pipes.enable = lib.mkDefault true;
          qutebrowser.enable = lib.mkDefault true;

          # favor neovim
          vim.enable = lib.mkOverride 0 false;

          neovim-custom = {
            enable = lib.mkDefault true;
            viAlias = true;
            vimAlias = true;
            defaultEditor = true;
          };
          yazi-custom = {
            enable = lib.mkDefault true;
          };
          zsh-custom = {
            enable = lib.mkDefault true;
          };
          tmux-custom = {
            enable = lib.mkDefault true;
          };

          # other good programs I use
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
          # I hate having to use this but I have to since many apps hardcode this one and I like the filemanager to be uniform.
          nautilus.enable = true;
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

          # used for some cron jobs throughout scripts
          cron.enable = true;
        };
      }
    ]
  );
}
