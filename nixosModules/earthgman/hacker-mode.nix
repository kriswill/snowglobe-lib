# basically turns nixos into kali linux
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.hacker-mode;
in
{
  options.earthgman.hacker-mode.enable = lib.mkEnableOption "EarthGman's cybersecurity suite";
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (config.system.desktop != null) {
        programs = {
          ghidra.enable = lib.mkDefault true;
          john.package = lib.mkDefault pkgs.johnny;
          nmap.package = lib.mkDefault pkgs.zenmap;
          tor-browser.enable = lib.mkDefault true;
          wireshark.package = lib.mkDefault pkgs.wireshark; # install gui version if desktop is enabled
        };
        environment.systemPackages = lib.mkIf config.programs.nmap.enable [
          # provide CLI with zenmap
          pkgs.nmap
        ];
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
            python3
            binutils
            busybox
            dig
            ;
        };
      }
    ]
  );
}
