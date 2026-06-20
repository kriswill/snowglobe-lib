{
  mkSteamServer,
  xvfb,
  libxi,
  callPackage,
}:
let
  # Use our deterministic fetcher (strips steamcmd bookkeeping) instead of
  # flux's `fetchSteam`, whose output hash drifts between runs/machines.
  fetchSteam = callPackage ./fetchSteam { };
in
mkSteamServer rec {
  name = "corekeeper";
  src = fetchSteam {
    inherit name;
    appId = "1963720";
    # Core Keeper Dedicated Server, buildid 23543502.
    hash = "sha256-dRntD5Th20a4H44QzEaDOBOh7KN7lLoj3QAL5wllBNk=";
  };

  buildInputs = [
    xvfb
    libxi
  ];

  startCmd = "_launch.sh";

  # mkSteamServer's build stage just chmod +x's the (already-executable) launch
  # script and re-copies, so the build output is byte-identical to src above.
  hash = "sha256-dRntD5Th20a4H44QzEaDOBOh7KN7lLoj3QAL5wllBNk=";
}
