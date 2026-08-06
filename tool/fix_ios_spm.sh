#!/bin/sh
# Fix Xcode/SwiftPM artifact-cache corruption that produces errors like:
#   file not found at path: .../SourcePackages/artifacts/firebase-ios-sdk/.../FirebaseAnalytics.zip
# `flutter clean` does NOT fix this — it doesn't touch Xcode's SPM caches, which
# live outside the Flutter build tree. Run with:
#   sh tool/fix_ios_spm.sh
# or: rps iosfix

set -e
repo_root=$(git rev-parse --show-toplevel)
ios_dir="$repo_root/ios"

echo "==> Discarding uncommitted Package.resolved drift (leftover from an interrupted resolve)"
cd "$repo_root"
git checkout -- \
  ios/Podfile.lock \
  ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved \
  ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved \
  2>/dev/null || true

echo "==> Purging Xcode DerivedData for Runner"
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

echo "==> Purging global SwiftPM caches"
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/org.swift.swiftpm
rm -rf "$ios_dir/.swiftpm"

echo "==> Reinstalling CocoaPods (deintegrate + install)"
cd "$ios_dir"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
pod deintegrate
pod install

echo "==> Resolving Swift packages fresh"
if ! xcodebuild -resolvePackageDependencies -workspace Runner.xcworkspace -scheme Runner; then
  echo "==> Initial resolve failed — clearing partially-downloaded artifacts and retrying once"
  rm -rf ~/Library/Caches/org.swift.swiftpm/artifacts/*grpc*
  rm -rf ~/Library/Caches/org.swift.swiftpm/artifacts/*Sentry*
  rm -rf ~/Library/Caches/org.swift.swiftpm/artifacts/*sentry*
  xcodebuild -resolvePackageDependencies -workspace Runner.xcworkspace -scheme Runner
fi

echo "✓ SPM/Pods state reset. Now Clean Build Folder (⇧⌘K) in Xcode and rebuild."
