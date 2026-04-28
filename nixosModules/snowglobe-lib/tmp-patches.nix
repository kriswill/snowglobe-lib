# used to temporarily patch modules or packages that fail to build for a specific flake input revision.
{
  pkgs,
  lib,
  config,
  ...
}:
{
  # snowglobe-lib = {
  #   overlays = {
  #     rmpc-git.enable = false;
  #   };
  # };
}
