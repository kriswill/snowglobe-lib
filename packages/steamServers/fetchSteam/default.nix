# Deterministic variant of flux's `fetchSteam`.
#
# Upstream's builder does a blind `cp -r . $out` of the steamcmd install dir,
# which captures steamcmd's per-run bookkeeping (steamapps/appmanifest_*.acf
# holds a LastUpdated timestamp and BytesDownloaded counters, plus transient
# downloading/ and temp/ scratch dirs). That makes the fixed-output hash drift
# between runs/machines even when the game build is unchanged. We strip that
# metadata in our own builder so the hash depends only on actual depot content.
{
  lib,
  stdenvNoCC,
  steamcmd,
}:
{
  name,
  appId,
  branch ? null,
  hash,
}:
stdenvNoCC.mkDerivation {
  name = "${name}-src";
  inherit appId branch;
  builder = ./builder.sh;
  buildInputs = [
    steamcmd
  ];

  outputHash = hash;
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
}
