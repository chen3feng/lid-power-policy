#!/bin/sh
# Show the current power policy state. No root required for the pmset/ioreg
# parts; the launchd section needs sudo.

LABEL=local.lid-power-policy

echo "Power source:"
pmset -g ps | head -1
echo

echo "Lid state:"
ioreg -r -k AppleClamshellState -d 4 2>/dev/null \
    | grep AppleClamshellState || echo "  (unavailable)"
echo

echo "SleepDisabled:"
pmset -g | grep -i sleepdisabled || echo "  (not set)"
echo

echo "Hibernation:"
pmset -g | grep -E 'hibernatemode|standby' || true
echo

echo "LaunchDaemon:"
launchctl print system/$LABEL 2>/dev/null | sed -n '1,12p' \
    || echo "  not loaded (or run with sudo)"
