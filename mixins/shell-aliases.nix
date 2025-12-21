{
  lib,
  config,
  ...
}:
let
  has-nh = config.programs.nh.enable;
  has-git = config.programs.git.enable;
  has-eza = config.programs.eza.enable;
in
{
  l = if (has-eza) then "eza -al --icons" else "ls -al";
  ls = lib.mkIf (has-eza) "eza --icons";
  g = "git";
  t = "tree";
  ff = lib.mkIf config.programs.fastfetch.enable "fastfetch";
  hh = lib.mkIf config.programs.hstr.enable "hstr";
  lg = lib.mkIf has-git "lazygit";
  ni = lib.mkIf config.programs.nix-inspect.enable "nix-inspect";
  ga = lib.mkIf has-git "git add .";
  gco = lib.mkIf has-git "git checkout";
  gba = lib.mkIf has-git "git branch -a";
  cat = lib.mkIf config.programs.bat.enable "bat";
  nrs =
    if (has-nh) then
      "nh os switch $(readlink -f /etc/nixos)"
    else
      "sudo nixos-rebuild switch --flake $(readlink -f /etc/nixos)";
  nrt =
    if (has-nh) then
      "nh os test $(readlink -f /etc/nixos)"
    else
      "sudo nixos-rebuild test --flake $(readlink -f /etc/nixos)";
  nrb = "nixos-rebuild build";
  ncg = if (has-nh) then "nh clean all" else "sudo nix-collect-garbage -d";
  npu = "nix-prefetch-url";
  npg = "nix-prefetch-git";
}
