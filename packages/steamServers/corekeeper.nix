{
  mkSteamServer,
  xvfb,
  libxi,
  fetchSteam,
}:
let
  hash = "sha256-YZO507X0Cg/S1kYY1sp0HeFE7YupkcRPLqKI2RH4IW0=";
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
