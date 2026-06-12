{
  description = "Core modules for the NixOS snowglobes framework.";

  outputs =
    { nixpkgs, self, ... }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      flake = self;
      outputs = flake.outputs;
      lib = nixpkgs.lib;
      import-tree = inputs.import-tree;

      snowglobe-lib = import ./lib/functions {
        inherit
          inputs
          outputs
          lib
          ;
      };
    in
    {
      # expose custom functions for use with other flakes and projects
      lib = snowglobe-lib;

      nixosModules = rec {
        snowglobe-lib = {
          imports = [
            (import-tree [
              ./nixosModules/snowglobe-lib
              { nixpkgs.overlays = builtins.attrValues outputs.overlays; }
              outputs.nixosModules.nixos
              # improved disk partition management
              inputs.disko.nixosModules.default
              # queue system for nix post-build-hook when uploading to binary caches
              inputs.nix-post-build-hook-queue.nixosModules.default
              inputs.nix-index-database.nixosModules.default
            ])
            # secrets storage and key management
            # does not work with import-tree for some reason
            inputs.sops-nix.nixosModules.default
          ];
        };
        # nixos module patches
        nixos = import-tree ./nixosModules/nixos;
        # jovian configuration
        jovian = import ./nixosModules/jovian { inherit inputs lib; };
        # expose the modules from nixos-hardware because they do not wrap them with options for some reason
        nixos-hardware = inputs.nixos-hardware.nixosModules;
        default = snowglobe-lib;
      };

      nixosConfigurations = import ./nixosConfigurations {
        inherit outputs lib;
        slib = snowglobe-lib;
      };

      packages = lib.genAttrs supportedSystems (
        system:
        let
          pkgs = import nixpkgs {
            config.allowUnfree = true;
            inherit system;
            overlays = builtins.attrValues flake.outputs.overlays;
          };
        in
        import ./packages { inherit pkgs; }
      );

      overlays = import ./overlays { inherit flake; };

      devShells = lib.genAttrs supportedSystems (system: {
        default = import ./devshell.nix {
          inherit flake;
          pkgs = nixpkgs.legacyPackages.${system};
        };
      });
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:/nixos/nixpkgs/nixos-26.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flux = {
      url = "github:iogamaster/flux";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jovian-nixos = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree = {
      url = "github:vic/import-tree";
    };

    nixos-hardware = {
      url = "https://flakehub.com/f/NixOS/nixos-hardware/*.tar.gz";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-post-build-hook-queue = {
      url = "github:newam/nix-post-build-hook-queue";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt.follows = "";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
