#!/bin/sh
# Install lid-power-policy as a system LaunchDaemon.
set -eu

if [ "$(uname -s)" != "Darwin" ]; then
    echo "This tool only supports macOS." >&2
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo $0" >&2
    exit 1
fi

HERE=$(cd "$(dirname "$0")" && pwd)
LABEL=local.lid-power-policy
DAEMON=/Library/LaunchDaemons/$LABEL.plist
TARGET=/usr/local/sbin/lid-power-policy.sh

# Safe default: allow lid-close sleep until the daemon says otherwise.
pmset disablesleep 0

install -d -m 755 /usr/local/sbin
install -m 755 -o root -g wheel "$HERE/lid-power-policy.sh" "$TARGET"
install -m 644 -o root -g wheel "$HERE/$LABEL.plist" "$DAEMON"

# Replace any previous instance.
launchctl bootout system/$LABEL 2>/dev/null || true
launchctl bootstrap system "$DAEMON"
launchctl enable system/$LABEL

echo "Installed $LABEL."
pmset -g | grep -i sleepdisabled || true
echo "Check with: ./status.sh"
