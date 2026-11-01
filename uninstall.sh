#!/bin/sh
# Remove lid-power-policy and restore the default lid-close sleep behavior.
set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo $0" >&2
    exit 1
fi

LABEL=local.lid-power-policy

launchctl bootout system/$LABEL 2>/dev/null || true
rm -f /Library/LaunchDaemons/$LABEL.plist
rm -f /usr/local/sbin/lid-power-policy.sh
rm -f /var/log/lid-power-policy.log

# Leave the machine in the safe state: lid close sleeps.
pmset disablesleep 0

echo "Uninstalled $LABEL."
