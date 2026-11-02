# Sideload APK update — publish checklist (Spark-friendly)

In-app updates read Firestore `config/app_version` (Spark OK), then download
the APK from a **public HTTPS URL** (`apkUrl`). Firebase Storage is **not**
required — Storage on this project needs Blaze, which we skip.

## Host the APK (pick one)

Good free options:

1. **GitHub Releases** — create a release, attach `app-release.apk`, copy the
   asset download URL (`https://github.com/.../releases/download/.../….apk`).
2. **Any CDN / static host** that serves a direct `.apk` link (no HTML login wall).

Avoid Google Drive / Dropbox “share” pages unless you have a real direct link.

## 1. Bump version

In `pubspec.yaml`:

```yaml
version: 1.0.2+3   # name+code — code must increase every release
```

## 2. Build release APK

```powershell
& "D:\flutter sdk\flutter\bin\flutter.bat" build apk --release --dart-define-from-file=secrets/dart_defines.json
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## 3. Upload APK + copy HTTPS URL

Upload the APK to GitHub Releases (or your host). Copy the **direct** download URL.

## 4. Update Firestore doc

Create/update document `config/app_version` (sample:
[`scripts/seed_app_version.json`](../scripts/seed_app_version.json)):

| Field | Example |
|-------|---------|
| `latestVersionCode` | `3` (number) |
| `latestVersionName` | `"1.0.2"` (string) |
| `apkUrl` | `"https://github.com/you/repo/releases/download/v1.0.2/app-release.apk"` |
| `forceUpdate` | `false` (boolean) |
| `minVersionCode` | `1` (number) |
| `releaseNotes` | `"…"` (string) |

Console: Firestore → collection `config` → document `app_version`.

- Soft update: `forceUpdate: false` and local code ≥ `minVersionCode` → Later allowed.
- Forced: `forceUpdate: true` **or** local code &lt; `minVersionCode` → cannot dismiss.

## 5. Verify on a phone

1. Install an older build (lower `versionCode`).
2. Sign in → Update dialog should appear.
3. Tap Update → allow “install unknown apps” for AeroFit if prompted → install.
4. Settings footer should show the new `version+code`.
