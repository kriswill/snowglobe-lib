{ pkgs, ... }:
let
  buildVimPlugin = pkgs.vimUtils.buildVimPlugin;
  fetchFromGitHub = pkgs.fetchFromGitHub;
in
{
  shellcheck-nvim = buildVimPlugin {
    pname = "shellcheck.nvim";
    version = "04.07.2025";
    src = fetchFromGitHub {
      owner = "pablos123";
      repo = "shellcheck.nvim";
      rev = "ee40e705ea61a4d790907c93cd01cc52480351fa";
      hash = "sha256-1rfEtD+II1uh6cn/dBxwGKxNFUwgoKXWtcJHIi6ydy4=";
    };
  };

  tuxedo-nvim = buildVimPlugin {
    pname = "tuxedo.nvim";
    version = "06.11.2026";
    src = fetchFromGitHub {
      owner = "iogamaster";
      repo = "tuxedo.nvim";
      rev = "65650b0ae3b1c3755a43306b07ada13bd78d47ac";
      hash = "sha256-e8Vk2QvMNDDpYCiTWwm5IgDlDhVKj2g+kNHpLbkYGx4=";
    };
  };
}
