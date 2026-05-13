# basically turns nixos into kali linux
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-lib.profiles.hacker-mode;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-lib.profiles.hacker-mode.enable =
    lib.mkEnableOption "Snowglobe-Lib's cybersecurity suite. Installs a majority of tools present on Kali.";
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (config.snowglobe-lib.desktop.enable) {
        programs = {
          ghidra.enable = lib.mkDefault true;
          zenmap.enable = lib.mkDefault true;
          tor-browser.enable = lib.mkDefault true;
          wireshark.package = lib.mkDefault pkgs.wireshark; # install gui version if desktop is enabled
        };
      })
      {
        programs = {
          tcpdump.enable = lib.mkDefault true;
          metasploit.enable = lib.mkDefault true;
          lynx.enable = lib.mkDefault true;
          binsider.enable = lib.mkDefault true;
          wireshark.enable = lib.mkDefault true;
          traceroute.enable = lib.mkDefault true;
          nmap.enable = lib.mkDefault true;
          john.enable = lib.mkDefault true;
        };

        environment.systemPackages = builtins.attrValues {
          inherit (pkgs)
            binutils
            dnsutils
            ;
        };
      }
    ]
  );
}
