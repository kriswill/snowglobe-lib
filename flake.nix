{
  description = "Gman's nix config";

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      supported-systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      myLib = (
        import ./lib {
          inherit inputs;
          lib = nixpkgs.lib;
          outputs = self.outputs;
        }
      );
      lib = nixpkgs.lib.extend (final: prev: (myLib));
    in
    {
      inherit lib;

      nixosModules = rec {
        gman = import ./nixosModules { inherit inputs lib; };
        default = gman;
      };

      nixosConfigurations = import ./hosts { inherit lib inputs; };

      packages = lib.genAttrs supported-systems (
        system:
        import ./packages {
          inherit inputs;
          pkgs = nixpkgs.legacyPackages.${system};
        }
      );

      overlays = import ./overlays.nix { inherit inputs; };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";

    dotfiles = {
      # url = "/home/g/src/git/codeberg.org/earthgman/dotfiles";
      url = "git+https://git.earthgman.dev/EarthGman/dotfiles";
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

    niri = {
      url = "github:YaLTeR/niri";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "";
    };

    # nix-gaming = {
    #   url = "github:fufexan/nix-gaming";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    prismlauncher = {
      url = "github:PrismLauncher/PrismLauncher";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "https://flakehub.com/f/Mic92/sops-nix/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yazi = {
      url = "github:sxyazi/yazi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
