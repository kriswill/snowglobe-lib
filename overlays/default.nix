{ flake }:
let
  inputs = flake.inputs;
in
rec {
  snowglobe-pkgs =
    # custom packages
    final: prev:
    import ../packages {
      pkgs = final;
    }
    # patches for things that dont build or aren't packaged correctly
    // import ./package-patches {
      inherit final prev;
      nixpkgs-stable = inputs.nixpkgs-stable.legacyPackages.${prev.stdenv.hostPlatform.system};
    }
    # extra vim plugins not in nixpkgs
    // {
      vimPlugins =
        prev.vimPlugins
        // import ../packages/vimPlugins {
          pkgs = final;
        };
    };

  nix-post-build-hook-queue = inputs.nix-post-build-hook-queue.overlays.default;
  flux = inputs.flux.overlays.default;
  default = snowglobe-pkgs;
}
