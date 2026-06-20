#!/bin/bash
# shellcheck source=/dev/null
if [ -e .attrs.sh ]; then source .attrs.sh; fi
source "${stdenv:?}/setup"

export HOME
HOME=$(mktemp -d)

mkdir -p "$out"
mkdir -p downloadDir
cd downloadDir

# steamcmd intermittently bails on the first anonymous app_update with
# "Failed to install app ... (Missing configuration)" - it fetches account/app
# config on one run and only downloads on a subsequent one. Retry a few times so
# the build doesn't fail randomly.
ok=
for attempt in 1 2 3 4 5; do
  echo "steamcmd app_update attempt $attempt..."
  if steamcmd +force_install_dir "$(pwd)" +login anonymous +app_update "$appId" validate +quit; then
    ok=1
    break
  fi
  echo "steamcmd attempt $attempt failed; retrying"
done
[ -n "$ok" ] || { echo "steamcmd failed after repeated attempts" >&2; exit 1; }

# steamcmd writes per-run bookkeeping into steamapps/: appmanifest_*.acf carries
# a LastUpdated timestamp and BytesDownloaded counters (which vary with the cache
# /delta state of each run), plus downloading/ and temp/ scratch dirs. None of it
# is game content - the depot files land at the install root - so drop it to keep
# the fixed-output hash dependent only on the actual game build.
rm -rf steamapps

cp -r . "$out"
