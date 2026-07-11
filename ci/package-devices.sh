#!/usr/bin/env bash
# Package Connect IQ device definition files for CI.
#
# Garmin gates device-file downloads behind a developer login, so CI
# can't fetch them itself. Run this once on a machine where the Connect
# IQ SDK Manager (or the VS Code Monkey C extension) has already
# downloaded devices, then commit the resulting ci/devices.tar.gz:
#
#   ./ci/package-devices.sh epix2pro47mm fenix7
#   git add ci/devices.tar.gz && git commit -m "Add CI device files"
#
# On Windows the device files live in %APPDATA%\Garmin\ConnectIQ\Devices
# (run this script from Git Bash and it will find them).
set -euo pipefail

DEVICES=("${@:-epix2pro47mm}")

for src in "$HOME/.Garmin/ConnectIQ/Devices" "${APPDATA:-}/Garmin/ConnectIQ/Devices"; do
    if [ -d "${src:-}" ]; then
        SRC="$src"
        break
    fi
done
if [ -z "${SRC:-}" ]; then
    echo "error: no Connect IQ device files found." >&2
    echo "Install a device via the SDK Manager / VS Code extension first." >&2
    exit 1
fi

for d in "${DEVICES[@]}"; do
    if [ ! -d "$SRC/$d" ]; then
        echo "error: device '$d' not found in $SRC" >&2
        echo "available: $(ls "$SRC" | tr '\n' ' ')" >&2
        exit 1
    fi
done

mkdir -p "$(dirname "$0")"
tar -czf "$(dirname "$0")/devices.tar.gz" -C "$SRC" "${DEVICES[@]}"
echo "wrote $(dirname "$0")/devices.tar.gz ($(du -h "$(dirname "$0")/devices.tar.gz" | cut -f1)) with: ${DEVICES[*]}"
