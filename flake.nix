{
  description = "Core modules for the NixOS snowglobes framework.";

  outputs =
    { nixpkgs, self, ... }@inputs:
    let
      outputs = self.outputs;

      myLib = import ./lib/functions {
        inherit
          inputs
          outputs
          ;
        lib = nixpkgs.lib;
      };
      lib = nixpkgs.lib.extend (final: prev: (myLib));

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      inherit lib;

      nixosModules = rec {
        snowglobe-core = import ./nixosModules/snowglobe-core { inherit lib inputs outputs; };
        earthgman = import ./nixosModules/earthgman;
        # jovian configuration
        jovian = import ./nixosModules/jovian { inherit inputs lib; };
        # expose the modules from nixos-hardware because they do not wrap them with options for some reason
        nixos-hardware = inputs.nixos-hardware.nixosModules;
        default = earthgman;
      };

      packages = lib.genAttrs supportedSystems (
        system:
        let
          pkgs = import nixpkgs {
            config.allowUnfree = true;
            inherit system;
            overlays = builtins.attrValues self.outputs.overlays;
          };
        in
        import ./packages { inherit pkgs; } // import ./packages/self-maintained/lutris { inherit pkgs; }
      );

      overlays = import ./overlays { inherit inputs; };

      nixosConfigurations = import ./nixosConfigurations { inherit lib; };

      devShells = lib.genAttrs supportedSystems (system: {
        default = import ./devShells { pkgs = nixpkgs.legacyPackages.${system}; };
      });
    };

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable"; # Stable Nixpkgs (use 0.1 for unstable
    };

    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dotfiles = {
      url = "git+https://git.earthgman.dev/earthgman/dotfiles";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.yazi.follows = "yazi";
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jovian-nixos = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    manga-tui = {
      url = "github:josueBarretogit/manga-tui";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "https://flakehub.com/f/NixOS/nixos-hardware/*.tar.gz";
    };

    nh = {
      url = "github:nix-community/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:niri-wm/niri";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "";
    };

    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        disko.follows = "";
        nixos-stable.follows = "";
        nixos-images.follows = "";
        nix-vm-test.follows = "";
        treefmt-nix.follows = "";
      };
    };

    prismlauncher = {
      url = "github:PrismLauncher/PrismLauncher";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rmpc = {
      url = "github:mierak/rmpc";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yazi = {
      url = "github:sxyazi/yazi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
