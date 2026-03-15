{
  description = "EarthGman's hub for all things Nix and NixOS";

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
        earthgman = import ./nixosModules/earthgman { inherit inputs outputs lib; };
        # jovian configuration
        jovian = import ./nixosModules/jovian { inherit inputs lib; };
        # expose the modules from nixos-hardware because they do not wrap them with options for some reason
        nixos-hardware = inputs.nixos-hardware.nixosModules;
        default = earthgman;
      };

      packages = lib.genAttrs supportedSystems (
        system:
        import ./packages {
          inherit inputs;
          pkgs = import nixpkgs {
            config.allowUnfree = true;
            inherit system;
            overlays = builtins.attrValues self.outputs.overlays;
          };
        }
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
      url = "git+https://git.earthgman.dev/earthgman/dotfiles?ref=dev";
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
      url = "https://flakehub.com/f/Mic92/sops-nix/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yazi = {
      url = "github:sxyazi/yazi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
