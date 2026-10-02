# Flock Manager - Common Commands

## Shell Aliases (defined in ~/.zshrc)

| Alias    | Command                                       |
|----------|-----------------------------------------------|
| `flock`  | `cd` to project directory                     |
| `fios`   | Build release IPA and open output folder      |
| `fapk`   | Build release AAB and open output folder      |
| `fclean` | Clean build, fetch deps, reinstall pods       |
| `fxc`    | Open Xcode workspace                          |
| `farchive` | Open last built `.xcarchive` in Xcode Organizer |

## Flutter

```bash
flutter run                        # Run debug on connected device/simulator
flutter run --release              # Run release build
flutter run -d <device_id>         # Run on specific device
flutter devices                    # List connected devices
flutter test                       # Run all tests (skips integration_test/)
flutter test integration_test/share_sheet_test.dart -d <device_id>
                                   # On-device share sheet checks (#41)
flutter pub get                    # Fetch dependencies
flutter pub outdated               # Check for outdated packages
flutter pub upgrade                # Upgrade dependencies (within constraints)
flutter build ipa --release        # Build iOS archive + IPA
flutter build appbundle --release  # Build Android AAB
flutter build apk --release       # Build Android APK (for device testing)
flutter clean                      # Delete build artifacts
flutter build ios --release --config-only
                                   # Repair ios/Flutter/Generated.xcconfig after
                                   # an integration-test run (see note below)
flutter upgrade                    # Upgrade Flutter SDK itself
```

**After running integration tests, before archiving in Xcode:** a
`flutter test integration_test/... -d <device>` run rewrites
`ios/Flutter/Generated.xcconfig` to point `FLUTTER_TARGET` at a temporary test
listener and leaves it there. The temp file is then deleted, so archiving fails
in the Run Script phase with `No such file or directory ... listener.dart` /
`No 'main' method found`, and `TRACK_WIDGET_CREATION` is left on. Run
`flutter build ios --release --config-only` first, or use `flutter build ipa`
instead of archiving from Xcode.

## Dart / Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs  # Run Freezed/codegen
dart run build_runner watch --delete-conflicting-outputs  # Watch mode for codegen
dart analyze                                              # Static analysis
dart fix --apply                                          # Auto-fix lint issues
```

## iOS / Xcode

```bash
open ios/Runner.xcworkspace              # Open project in Xcode
cd ios && pod install && cd ..           # Install CocoaPods
cd ios && pod install --repo-update      # Install pods + update repo
cd ios && pod deintegrate && pod install  # Full pod reset
xcrun simctl list devices                # List simulators
xcrun simctl boot <device_id>            # Boot a simulator
xcrun simctl erase <device_id>           # Factory reset a simulator
```

## Android

```bash
flutter build appbundle --release   # Build AAB for Play Store
flutter build apk --release         # Build APK for sideloading
adb install build/app/outputs/flutter-apk/app-release.apk  # Install APK on device
adb devices                         # List connected Android devices
```

## Git (project aliases from ~/.zshrc)

| Alias      | Command                      |
|------------|------------------------------|
| `gs`       | `git status`                 |
| `gb`       | `git branch`                 |
| `gbc`      | `git branch --show-current`  |
| `gc`       | `git checkout`               |
| `gd`       | `git diff`                   |
| `gp`       | `git pull`                   |
| `grelease` | `git push origin main --tags`|

## Release Workflow

1. Merge feature branch to main
2. `flutter test`
3. Bump version in `pubspec.yaml` (version + build number)
4. Commit version bump, push, tag (`git tag v1.x.x`)
5. `fios` (iOS) / `fapk` (Android)
6. Upload IPA via Transporter, AAB via Google Play Console
