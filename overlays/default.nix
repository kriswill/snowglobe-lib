{ inputs, lib }:
{
  default =
    # custom packages
    final: prev:
    import ../packages {
      pkgs = final;
    };

  package-fixes = import ./package-fixes;

  nix-post-build-hook-queue = inputs.nix-post-build-hook-queue.overlays.default;
}
