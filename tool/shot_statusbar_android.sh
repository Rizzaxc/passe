#!/usr/bin/env bash
# Dresses a running Android emulator for Play Store capture via SystemUI demo
# mode, the Android equivalent of simctl's status bar override.
#
# Demo mode must be explicitly allowed once per device, and it is CLEARED on
# reboot (and by `exit`), so re-run after any restart.
#
# Usage:  sh tool/shot_statusbar_android.sh [SERIAL]
set -euo pipefail
SERIAL="${1:-}"
ADB=(adb)
[ -n "$SERIAL" ] && ADB=(adb -s "$SERIAL")

"${ADB[@]}" shell settings put global sysui_demo_allowed 1
d() { "${ADB[@]}" shell am broadcast -a com.android.systemui.demo "$@" >/dev/null; }

d -e command enter
d -e command clock   -e hhmm 0941
d -e command battery -e level 100 -e plugged false
d -e command network -e wifi show -e level 4
d -e command network -e mobile show -e datatype none -e level 4
d -e command notifications -e visible false

echo "demo mode on. capture:"
echo "  ${ADB[*]} exec-out screencap -p > ~/Desktop/shot_01.png"
echo "  ${ADB[*]} shell screenrecord /sdcard/clip.mp4   (ctrl-C, then: ${ADB[*]} pull /sdcard/clip.mp4)"
echo "reset:"
echo "  ${ADB[*]} shell am broadcast -a com.android.systemui.demo -e command exit"
