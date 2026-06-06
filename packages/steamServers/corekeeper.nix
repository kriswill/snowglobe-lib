{
  mkSteamServer,
  xvfb,
  libxi,
  fetchSteam,
}:
mkSteamServer rec {
  name = "corekeeper";
  src = fetchSteam {
    inherit name;
    appId = "1963720";
    hash = "sha256-81OnQiy6mm0fcEA76H3WAJlm1uwQAc/2tytBKgKFy5k=";
  };

  buildInputs = [
    xvfb
    libxi
  ];

  startCmd = "_launch.sh";

  hash = "sha256-81OnQiy6mm0fcEA76H3WAJlm1uwQAc/2tytBKgKFy5k=";
}
