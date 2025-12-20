{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.yazi;
in
{
  options.gman.yazi = {
    enable = lib.mkEnableOption "gman's yazi configuration";
  };

  config = lib.mkIf cfg.enable {
    # only use to install dependency packages.
    environment.systemPackages = builtins.attrValues {
      inherit (pkgs)
        file
        mediainfo
        resvg
        ffmpeg
        imagemagick
        poppler
        wl-clipboard
        exiftool
        ;
    };

    programs = {
      fzf.enable = true;
      fd.enable = true;
      jq.enable = true;
      ripgrep.enable = true;
      zoxide.enable = true;

      yazi = {
        enable = true;
        package = pkgs.yazi.override {
          _7zz = pkgs._7zz-rar;
        };
      };
    };
  };
}
