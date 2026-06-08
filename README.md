# AeroFit

Personal lifestyle & fitness tracking — Flutter PWA with **Firebase** (Auth, Firestore, Storage) and optional Python meal vision API.

## Quick start

```powershell
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure
flutter run -d chrome --dart-define=DISPLAY_NAME=Minusha
```

Before FlutterFire setup, the dashboard shows demo data.

## Docs

- [Project structure](docs/PROJECT_STRUCTURE.md)
- [Firebase Web init](docs/FIREBASE_WEB_INIT.md)
- [Firebase setup](docs/FIREBASE_SETUP.md)
- [Vercel deploy](docs/VERCEL_DEPLOY.md)
- [PWA setup](docs/PWA_SETUP.md)
- [Firestore schema](firebase/firestore_schema.md)

## Stack

| Layer | Choice |
|-------|--------|
| UI | Flutter (dark mode, responsive shell) |
| State | Riverpod |
| Backend | Firebase Auth, Cloud Firestore, Firebase Storage |
| Charts | fl_chart (Reports screen — next phase) |
| ML meals | Custom Python API via `FoodVisionService` |
