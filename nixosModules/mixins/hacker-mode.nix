# provides a number of cybersecurity tools
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.hacker-mode;
in
{
  options.gman.hacker-mode.enable = lib.mkEnableOption "gman's cybersecurity suite";
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (config.meta.desktop != "") {
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
