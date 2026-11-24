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
- Web development: Google Chrome

## Run

```powershell
flutter pub get
flutter run -d windows
flutter run -d SHG08
flutter run -d chrome
```

To serve the web app without launching a browser, run
`flutter run -d web-server --web-port 8080` and open `http://localhost:8080`.

For Android, the app requests network access to report connectivity and perform
optional public-IP and ISP lookups. ISP is estimated from the public IP through
ipwho.is and may be unavailable due to service limits, device permissions,
platform limitations, or network policy. All reference catalogs remain
available offline.

## Build

```powershell
flutter build apk --release
flutter build windows --release
flutter build web --release
```

## Safety and privacy

- Windows repair, cleanup, and network commands are copied for technician
  review; the toolkit does not execute them. Temporary files are listed for
  review and are not deleted automatically.
- Saved Wi-Fi profile commands are generated for authorized local
  troubleshooting. The app does not extract or display saved passwords.
- System resource metrics are read from the local operating system. A metric
  unsupported by the platform, including browser-based web builds, is shown as
  unavailable rather than estimated.
- Generated service reports are saved to the platform downloads directory when
  available, otherwise to the app documents directory. Reports can also be
  shared or printed. Technicians can attach up to 10 photos with descriptions;
  the images and captions are embedded in the generated PDF.
- Proposal and BOQ generators are separate options under Tools. Proposals are
  saved as editable Word (`.docx`) documents; BOQs are saved as Excel (`.xlsx`)
  workbooks with calculated line and grand totals. BOQs support extra user-
  defined columns and rows. Recent proposals and BOQs are kept locally and can
  be opened from their generator pages. Empty optional proposal sections and
  unused BOQ columns are omitted from generated documents. All generated
  documents include the AHEAD AFRICA logo, company contact details, and a
  clickable website link.
