{ pkgs, ... }:
{
  nvim-vague = pkgs.vimUtils.buildVimPlugin {
    name = "nvim-vague";
    src = pkgs.fetchFromGitHub {
      owner = "vague2k";
      repo = "vague.nvim";
      rev = "ceeac4d04faaa83df542992098e01d893a20b5b3";
      sha256 = "10dk3vxdn7s2kaya0zqapls5dkl00qbdi3lzpxsjw0g1ga8cwdxz";
    };
  };

  shellcheck-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "shellcheck-nvim";
    src = pkgs.fetchFromGitHub {
      owner = "pablos123";
      repo = "shellcheck.nvim";
      rev = "ee40e705ea61a4d790907c93cd01cc52480351fa";
      hash = "sha256-1rfEtD+II1uh6cn/dBxwGKxNFUwgoKXWtcJHIi6ydy4=";
    };
  };

  vim-fern = pkgs.vimUtils.buildVimPlugin {
    name = "vim-fern";
    src = pkgs.fetchFromGitHub {
      owner = "lambdalisue";
      repo = "vim-fern";
      rev = "main";
      hash = "sha256-2XkM4Niq8FLxr/gNOBWaleggtgeb+SVIQZeLDtintR4=";
    };
  };
}
