{ flake }:
{
  # wrapper for lib.nixosSystem
  mkNixosHost = import ./mkNixosHost.nix { inherit flake; };
}
