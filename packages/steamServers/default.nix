# steam servers to be used with https://github.com/iogamaster/flux
{ pkgs, ... }:
{
  corekeeper = pkgs.mkSteamServer rec {
    name = "corekeeper";
    src = pkgs.fetchSteam {
      inherit name;
      appId = "1963720";
      hash = "sha256-81OnQiy6mm0fcEA76H3WAJlm1uwQAc/2tytBKgKFy5k=";
    };

    buildInputs = [
      pkgs.xvfb
      pkgs.libxi
    ];

    startCmd = "_launch.sh";

    hash = "sha256-81OnQiy6mm0fcEA76H3WAJlm1uwQAc/2tytBKgKFy5k=";
  };
}
