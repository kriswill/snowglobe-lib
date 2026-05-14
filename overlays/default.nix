{ inputs, lib }:
rec {
  packages =
    # custom packages
    final: prev:
    (
      (import ../packages {
        pkgs = final;
      })
      # patches for things that dont build or aren't packaged correctly
      // import ./package-patches { inherit final prev; }
    );

  nix-post-build-hook-queue = inputs.nix-post-build-hook-queue.overlays.default;

  default = packages;
}
