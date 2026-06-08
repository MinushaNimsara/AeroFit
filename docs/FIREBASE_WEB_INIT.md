# Firebase initialization — Flutter Web (AeroFit)

## Overview

Flutter Web uses **`firebase_core`** + **`firebase_options.dart`** (FlutterFire). You do **not** need to paste the legacy `<script src="firebase-app.js">` tags into `index.html` when using the official FlutterFire plugins.

---

## Step 1 — Firebase Console

1. [Firebase Console](https://console.firebase.google.com/) → your project.
2. **Project settings** → **Your apps** → **Add app** → **Web** (`</>`).
3. Register app nickname: `AeroFit Web`.
4. Copy the `firebaseConfig` object (you will use these values in Step 3).

Enable products:

| Product | Path |
|---------|------|
| Authentication | Build → Authentication → Get started |
| Cloud Firestore | Build → Firestore → Create database |
| Storage | Build → Storage → Get started |

Deploy rules from this repo:

```bash
firebase deploy --only firestore:rules,storage
```

---

## Step 2 — Add packages (already in `pubspec.yaml`)

```yaml
firebase_core: ^3.8.1
firebase_auth: ^5.3.4
cloud_firestore: ^5.6.0
firebase_storage: ^12.3.7
```

Run:

```powershell
flutter pub get
```

---

## Step 3 — Generate `firebase_options.dart` (local dev)

**Option A — FlutterFire CLI (recommended)**

```powershell
dart pub global activate flutterfire_cli
cd path\to\AeroFit
flutterfire configure
```

Select your Firebase project and platforms (include **Web**). This writes `lib/firebase_options.dart`.

**Option B — Vercel environment variables (CI)**

Set in Vercel → Project → Settings → Environment Variables:

| Variable | Example |
|----------|---------|
| `FIREBASE_API_KEY` | `AIza...` |
| `FIREBASE_APP_ID` | `1:123:web:abc` |
| `FIREBASE_MESSAGING_SENDER_ID` | `123456789` |
| `FIREBASE_PROJECT_ID` | `aerofit-xxxxx` |
| `FIREBASE_AUTH_DOMAIN` | `aerofit-xxxxx.firebaseapp.com` |
| `FIREBASE_STORAGE_BUCKET` | `aerofit-xxxxx.appspot.com` |

The Vercel build runs `dart run tool/generate_firebase_options.dart` when `FIREBASE_API_KEY` is set.

---

## Step 4 — Bootstrap in `main.dart` (already implemented)

```dart
import 'package:aerofit/core/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  runApp(const ProviderScope(child: AeroFitApp()));
}
```

`lib/core/firebase/firebase_bootstrap.dart`:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Skips init if `DefaultFirebaseOptions.isConfigured` is false (demo dashboard).

---

## Step 5 — Authorized domains (required for production)

Firebase Console → **Authentication** → **Settings** → **Authorized domains**

Add:

- `localhost` (dev)
- Your Vercel domain: `your-app.vercel.app`
- Custom domain if configured

---

## Step 6 — Firestore user profile on first sign-in

After Auth sign-up/sign-in, merge a profile document:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> ensureUserProfile(User user) async {
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'displayName': user.displayName ?? 'Minusha',
    'dailyCalorieGoal': 2000,
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
```

Schema: [`firebase/firestore_schema.md`](../firebase/firestore_schema.md).

---

## Step 7 — Run Flutter Web locally

```powershell
flutter run -d chrome --dart-define=DISPLAY_NAME=Minusha
```

Verify in DevTools → Application → Service Workers (PWA) and Firebase Auth/Firestore in Network tab.

---

## Step 8 — Riverpod providers (already wired)

| Provider | Purpose |
|----------|---------|
| `firebaseAuthProvider` | `FirebaseAuth.instance` |
| `firestoreProvider` | `FirebaseFirestore.instance` |
| `firebaseStorageProvider` | `FirebaseStorage.instance` |
| `authStateProvider` | `authStateChanges()` stream |
| `dailyStatusProvider` | Aggregates today's Firestore data |

---

## Security note

Firebase Web API keys are **not secret**; security is enforced by **Firestore/Storage rules** (`firebase/firestore.rules`, `firebase/storage.rules`). Never commit service account JSON to the repo.
