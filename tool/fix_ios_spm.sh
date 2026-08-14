#!/bin/sh
# Fix Xcode/SwiftPM problems in two categories:
#
# 1. Artifact-cache corruption, e.g.:
#      file not found at path: .../SourcePackages/artifacts/firebase-ios-sdk/.../FirebaseAnalytics.zip
#      Missing package product 'FlutterGeneratedPluginSwiftPackage'
#    `flutter clean` does NOT fix this — it doesn't touch Xcode's SPM caches, which live
#    outside the Flutter build tree.
#
# 2. Stale deployment-target manifest, e.g.:
#      The package product 'firebase-core' requires minimum platform version 15.0 for the
#      iOS platform, but this target supports 13.0
#    `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift` is
#    regenerated on every Flutter build, but Flutter's migration that syncs its declared iOS
#    platform to the Xcode project's actual IPHONEOS_DEPLOYMENT_TARGET only runs during a
#    Flutter CLI build/config step — plain `flutter pub get` or opening Xcode directly leaves
#    it at Flutter's hardcoded 13.0 default, and Xcode resolves packages before any Flutter
#    build-phase script can fix it. See https://github.com/flutter/flutter/issues/186804.
#    `flutter build ios --config-only` below is what actually re-syncs it.
#
# Run with:
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

echo "==> flutter clean + wiping ios/Flutter/ephemeral (the generated SPM manifest lives here)"
flutter clean
rm -rf "$ios_dir/Flutter/ephemeral" "$ios_dir/Pods" "$ios_dir/Podfile.lock"

echo "==> Purging Xcode DerivedData for Runner"
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

echo "==> Purging global SwiftPM caches"
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/org.swift.swiftpm
rm -rf "$ios_dir/.swiftpm"

echo "==> flutter pub get"
flutter pub get

echo "==> Re-syncing FlutterGeneratedPluginSwiftPackage's deployment target to the Xcode project"
flutter build ios --config-only --no-codesign

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
