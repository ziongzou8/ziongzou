# ZIONGZOU Technician Toolkit

**AHEAD AFRICA SOLUTION LTD — One Toolkit. Every Technician.**

ZIONGZOU is an offline-first Flutter toolkit for Windows and Android technicians.
Its local catalogs include Windows keyboard shortcuts and commands, Android
device tips, command snippets, and troubleshooting guides. Favorites, recent
activity, and service-report history are stored locally with
`shared_preferences`.

## Requirements

- Flutter with Dart SDK `>=3.6.0 <4.0.0`
- Windows desktop development: Visual Studio 2022 with **Desktop development
  with C++**
- Android deployment: Android SDK/toolchain and a connected device with USB
  debugging enabled

## Run

```powershell
flutter pub get
flutter run -d windows
flutter run -d SHG08
```

For Android, the app requests network access to report connectivity and perform
an optional public-IP lookup. Network adapter details and public-IP lookups are
best-effort and may be unavailable due to device permissions, platform
limitations, or network policy. All reference catalogs remain available
offline.

## Build

```powershell
flutter build apk --release
flutter build windows --release
```

## Safety and privacy

- Windows repair, cleanup, and network commands are copied for technician
  review; the toolkit does not execute them. Temporary files are listed for
  review and are not deleted automatically.
- Saved Wi-Fi profile commands are generated for authorized local
  troubleshooting. The app does not extract or display saved passwords.
- System resource metrics are read from the local operating system. A metric
  unsupported by the platform is shown as unavailable rather than estimated.
- Generated service reports are saved to the platform downloads directory when
  available, otherwise to the app documents directory. Reports can also be
  shared or printed. Technicians can attach up to 10 photos with descriptions;
  the images and captions are embedded in the generated PDF.
