# AeroFit — Complete folder structure

```
aerofit/
├── assets/
│   └── images/                         # Static assets
├── docs/
│   ├── PROJECT_STRUCTURE.md            # This file
│   ├── FIREBASE_WEB_INIT.md            # Step-by-step Firebase Web setup
│   ├── FIREBASE_SETUP.md               # Auth, Firestore, Storage, rules
│   ├── VERCEL_DEPLOY.md                # Vercel + Flutter Web CI
│   └── PWA_SETUP.md                    # Install App prompt & PWA criteria
├── firebase/
│   ├── firestore.rules
│   ├── storage.rules
│   └── firestore_schema.md
├── lib/
│   ├── main.dart                       # FirebaseBootstrap + ProviderScope
│   ├── app.dart                        # MaterialApp.router, dark theme
│   ├── firebase_options.dart           # FlutterFire / Vercel-generated
│   ├── core/
│   │   ├── config/env.dart             # dart-define (ML API, goals, name)
│   │   ├── firebase/
│   │   │   ├── firebase_bootstrap.dart
│   │   │   ├── firebase_providers.dart # Auth, Firestore, Storage
│   │   │   └── firestore_paths.dart
│   │   ├── router/app_router.dart      # go_router + fade transitions
│   │   ├── services/food_vision_service.dart
│   │   └── theme/app_theme.dart
│   ├── features/
│   │   ├── dashboard/                  # ✅ Daily Hub
│   │   │   ├── data/dashboard_repository.dart
│   │   │   ├── domain/daily_status.dart
│   │   │   ├── providers/dashboard_providers.dart
│   │   │   └── presentation/
│   │   │       ├── dashboard_screen.dart
│   │   │       └── widgets/
│   │   │           ├── daily_goal_ring.dart
│   │   │           ├── daily_win_loss_banner.dart
│   │   │           ├── remaining_tasks_card.dart
│   │   │           └── status_pill_row.dart
│   │   ├── routine/
│   │   │   ├── data/                   # task_repository (next)
│   │   │   ├── domain/
│   │   │   └── presentation/routine_screen.dart
│   │   ├── workouts/
│   │   │   ├── data/                   # splits, storage uploads (next)
│   │   │   ├── domain/
│   │   │   └── presentation/workouts_screen.dart
│   │   ├── meals/
│   │   │   ├── data/                   # meal_repository (next)
│   │   │   ├── domain/
│   │   │   └── presentation/meals_screen.dart
│   │   └── analytics/
│   │       ├── data/                   # monthly aggregates (next)
│   │       ├── domain/
│   │       └── presentation/reports_screen.dart
│   └── shared/widgets/app_shell.dart   # Bottom nav + NavigationRail (web)
├── scripts/
│   ├── vercel-install.sh               # Flutter SDK on Vercel
│   └── vercel-build.sh                 # flutter build web --release
├── tool/
│   └── generate_firebase_options.dart  # CI: env → firebase_options.dart
├── test/widget_test.dart
├── web/
│   ├── index.html                      # PWA meta + Install App banner
│   ├── manifest.json
│   ├── favicon.png
│   └── icons/                          # 192, 512, maskable
├── vercel.json                         # Rewrites, headers, build commands
├── .vercelignore
├── pubspec.yaml
└── README.md
```

## Architecture summary

| Layer | Technology |
|-------|------------|
| UI | Flutter 3, dark Material 3, `flutter_animate` |
| Routing | `go_router` (deep links work on Vercel via rewrites) |
| State | Riverpod |
| Auth / DB / Files | Firebase Auth, Firestore, Storage |
| ML meals | HTTP → your Python API |
| Hosting | Vercel (`build/web`) |
| PWA | `manifest.json` + service worker + install banner |
