#!/usr/bin/env bash
# Dresses a booted iOS Simulator for App Store capture, and gives it a location.
#
# Apple's own marketing convention is a 9:41 clock, full bars and a full
# battery. simctl can override all of it, and the override SURVIVES app
# relaunches but NOT a simulator reboot -- re-run after any reboot.
#
# The location matters since the geolocator work landed: PDistanceLabel shows a
# "see distance" chip until location is granted, and real km only once there's a
# fix. Every seeded venue has real coordinates, so a simulated position in Binh
# Thanh makes those labels truthful rather than decorative.
#
# Usage:  sh tool/shot_statusbar_ios.sh [DEVICE]     (default: booted)
set -euo pipefail
DEV="${1:-booted}"

# Binh Thanh, HCMC -- where the hero and most seeded venues live.
LAT=10.8106
LON=106.7091

xcrun simctl status_bar "$DEV" override \
  --time "09:41" \
  --dataNetwork wifi \
  --wifiMode active \
  --wifiBars 3 \
  --cellularMode active \
  --cellularBars 4 \
  --batteryState charged \
  --batteryLevel 100

xcrun simctl location "$DEV" set "$LAT,$LON"

echo "status bar dressed + location set to $LAT,$LON on '$DEV'"
echo
echo "capture:   xcrun simctl io $DEV screenshot ~/Desktop/shot_01.png"
echo "record:    xcrun simctl io $DEV recordVideo --codec h264 ~/Desktop/clip_01.mp4   (ctrl-C to stop)"
echo "reset:     xcrun simctl status_bar $DEV clear"
