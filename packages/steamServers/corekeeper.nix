{
  mkSteamServer,
  xvfb,
  libxi,
  fetchSteam,
}:
let
  hash = "sha256-k+KaQirLZLuMyVTDa3enUMGfIG9w8KooUltBPL0TdX8=";
in
mkSteamServer rec {
  name = "corekeeper";
  src = fetchSteam {
    inherit name;
    appId = "1963720";
    inherit hash;
  };

  buildInputs = [
    xvfb
    libxi
  ];

  startCmd = "_launch.sh";
  inherit hash;
}
