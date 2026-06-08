# Firebase setup for AeroFit

## 1. Create a Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/).
2. **Add project** → name it `aerofit` (or your choice).
3. Enable **Google Analytics** (optional).

## 2. Register apps

### Web (PWA — required)

1. Project overview → **Add app** → **Web** (`</>`).
2. App nickname: `AeroFit Web`.
3. Copy the config object (apiKey, authDomain, projectId, etc.).

### Android / iOS (optional)

Add Android (`com.aerofit.aerofit`) and iOS bundles matching `firebase_options.dart`.

## 3. Enable products

| Product | Console path | Purpose |
|---------|----------------|---------|
| **Authentication** | Build → Authentication → Get started | Email/Google sign-in |
| **Cloud Firestore** | Build → Firestore → Create database | Tasks, meals, workouts |
| **Storage** | Build → Storage → Get started | Exercise & meal images |

Start Firestore in **production mode**, then deploy rules from this repo.

## 4. FlutterFire CLI (recommended)

```powershell
dart pub global activate flutterfire_cli
cd "c:\Users\KALUPAHANA AUTO CAR\Desktop\My project\AeroFit"
flutterfire configure
```

This regenerates `lib/firebase_options.dart` and platform config files (`google-services.json`, `GoogleService-Info.plist`).

## 5. Deploy security rules

Install Firebase CLI, then:

```powershell
firebase login
firebase init firestore storage   # select existing project, use firebase/ rules files
firebase deploy --only firestore:rules,storage
```

Rule files in this project:

- `firebase/firestore.rules`
- `firebase/storage.rules`

## 6. Authentication

Enable sign-in methods you need (e.g. **Email/Password**, **Google**).

For **Google on Web**, add your hosting domain and `localhost` to **Authorized domains** (Authentication → Settings).

Create a user profile document on first sign-in (Cloud Function or client):

```dart
await FirebaseFirestore.instance.collection('users').doc(uid).set({
  'displayName': 'Minusha',
  'dailyCalorieGoal': 2000,
  'createdAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
```

## 7. Firestore indexes

If queries fail in the console, create indexes for:

- `users/{uid}/daily_tasks` — `scheduledDate`
- `users/{uid}/meal_logs` — `logDate`
- `users/{uid}/workout_sessions` — `sessionDate`

Schema reference: [`firebase/firestore_schema.md`](../firebase/firestore_schema.md).

## 8. Run the app

```powershell
flutter pub get
flutter run -d chrome --dart-define=DISPLAY_NAME=Minusha
```

Until `flutterfire configure` replaces `REPLACE_ME` in `firebase_options.dart`, the dashboard uses **demo data**.

## 9. Python food vision API

Set your FastAPI/Flask URL when running:

```powershell
flutter run -d chrome --dart-define=FOOD_VISION_API_URL=https://your-api.com/analyze-food
```

Client: `lib/core/services/food_vision_service.dart`.

## 10. PWA + Firebase Hosting (production)

```powershell
flutter build web --release
firebase init hosting
firebase deploy
```

Serve over **HTTPS** so the PWA install prompt and Firebase Auth work reliably.
