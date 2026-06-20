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
    hash = "sha256-k+KaQirLZLuMyVTDa3enUMGfIG9w8KooUltBPL0TdX8=";
  };

  buildInputs = [
    xvfb
    libxi
  ];

  startCmd = "_launch.sh";

  hash = "sha256-k+KaQirLZLuMyVTDa3enUMGfIG9w8KooUltBPL0TdX8=";
}
