# update your timezon based on your geolocation (requires networkmanager and a network connection to update)
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-core.dynamic-timezone;
in
{
  options.snowglobe-core.dynamic-timezone = {
    enable = lib.mkEnableOption "geolocation based time synchronization";
    server = lib.mkOption {
      description = "URL of the server to use";
      type = lib.types.str;
      default = "https://ipapi.co/timezone";
    };
  };
  config = lib.mkIf cfg.enable {
    warnings =
      lib.optionals (!config.networking.networkmanager.enable) [
        ''
          Networkmanager is not enabled, The geolocation timesync module will not work properly. 
          You can enable networkmanager with networking.networkmanager.enable = true or disable the module with snowglobe-core.dynamic-timezone.enable = false.
        ''
      ]
      ++ (lib.optionals (config.time.timeZone != null) [
        ''
          the time.timeZone option must be `null` for the snowglobe-core.dynamic-timezone module to work.
        ''
      ]);

    networking.networkmanager.dispatcherScripts = [
      {
        # https://wiki.archlinux.org/title/NetworkManager#Automatically_set_the_timezone
        source = pkgs.writeText "10-update-timezone" ''
          case "$2" in
            "connectivity-change")
              timedatectl set-timezone "$(${pkgs.curlMinimal}/bin/curl --fail ${cfg.server})"
              ;;
            *)
              exit 0
              ;;
          esac
        '';
      }
    ];
  };
}
