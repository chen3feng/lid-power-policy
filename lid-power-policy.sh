#!/bin/sh
# Keep the Mac awake with the lid closed only while on AC power.
# On battery, lid close is allowed to sleep. Combined with
# `pmset -b hibernatemode 25`, sleeping writes RAM to disk and cuts
# power to memory, so a closed lid drains almost nothing.
#
# Installed at /usr/local/sbin/lid-power-policy.sh and run by
# /Library/LaunchDaemons/local.lid-power-policy.plist every few seconds.

PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH

# 1 when the power adapter is connected, 0 otherwise.
on_ac=0
external=$(ioreg -rn AppleSmartBattery 2>/dev/null \
           | awk -F'= ' '/"ExternalConnected"/ { print $2; exit }' \
           | tr -d '" ')
[ "$external" = "Yes" ] && on_ac=1

want=0
[ "$on_ac" -eq 1 ] && want=1

cur=$(pmset -g | awk '$1 == "SleepDisabled" { print $2; exit }')
[ -n "$cur" ] || cur=0

if [ "$cur" != "$want" ]; then
    pmset disablesleep "$want"

    # Just dropped to battery while the lid is already shut: sleep now.
    if [ "$want" -eq 0 ]; then
        lid=$(ioreg -r -k AppleClamshellState -d 4 2>/dev/null \
              | awk -F'= ' '/AppleClamshellState/ { print $2; exit }' \
              | tr -d '" ')
        [ "$lid" = "Yes" ] && pmset sleepnow
    fi
fi

exit 0
