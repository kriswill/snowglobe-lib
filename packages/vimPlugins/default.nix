{ pkgs, ... }:
let
  buildVimPlugin = pkgs.vimUtils.buildVimPlugin;
  fetchFromGitHub = pkgs.fetchFromGitHub;
in
{
  nvim-vague = buildVimPlugin {
    pname = "vague.nvim";
    src = fetchFromGitHub {
      owner = "vague2k";
      repo = "vague.nvim";
      rev = "ceeac4d04faaa83df542992098e01d893a20b5b3";
      sha256 = "10dk3vxdn7s2kaya0zqapls5dkl00qbdi3lzpxsjw0g1ga8cwdxz";
    };
  };

  shellcheck-nvim = buildVimPlugin {
    pname = "shellcheck.nvim";
    src = fetchFromGitHub {
      owner = "pablos123";
      repo = "shellcheck.nvim";
      rev = "ee40e705ea61a4d790907c93cd01cc52480351fa";
      hash = "sha256-1rfEtD+II1uh6cn/dBxwGKxNFUwgoKXWtcJHIi6ydy4=";
    };
  };

  tuxedo-nvim = buildVimPlugin {
    pname = "tuxedo.nvim";
    version = "0-unstable-06-11-2026";
    src = fetchFromGitHub {
      owner = "iogamaster";
      repo = "tuxedo.nvim";
      rev = "65650b0ae3b1c3755a43306b07ada13bd78d47ac";
      hash = "sha256-e8Vk2QvMNDDpYCiTWwm5IgDlDhVKj2g+kNHpLbkYGx4=";
    };
  };
}
