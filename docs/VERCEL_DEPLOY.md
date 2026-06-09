# Deploy AeroFit (Flutter Web PWA) on Vercel

## Prerequisites

- Git repo connected to Vercel
- Firebase Web app configured (`docs/FIREBASE_WEB_INIT.md`)

## 1. Vercel dashboard — turn OFF overrides

Go to **Vercel → Project → Settings → Build & Development Settings**.

For each row below, click **Override** so it is **disabled** (grey). Let `vercel.json` control the project:

| Setting | Must be |
|---------|---------|
| Framework Preset | **Other** |
| Root Directory | **empty** or `.` |
| Install Command | *not overridden* |
| Build Command | *not overridden* |
| Output Directory | *not overridden* |

If Override stays ON with old values (`build/web`, `bash scripts/...` from an earlier setup), deployments fail even when `vercel.json` is correct.

## 2. How deployment works (pre-built)

The repo commits the production Flutter bundle in **`web/`** (includes `main.dart.js`).

`vercel.json` runs lightweight scripts that:

1. Skip Flutter SDK install
2. Verify `web/main.dart.js` exists (or copy from `dist/` as fallback)
3. Serve **`web/`** as the static output

No Flutter build runs on Vercel servers.

## 3. Rebuild after code changes

```powershell
flutter build web --release --base-href /
Copy-Item -Path build\web\* -Destination web\ -Recurse -Force
git add web/
git commit -m "Update production web build"
git push origin main
```

Optional: keep `dist/` in sync with `bash scripts/prepare-vercel-dist.sh`.

## 4. Environment variables (optional)

Only needed if you stop committing `lib/firebase_options.dart`:

- `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`, `FIREBASE_AUTH_DOMAIN`, `FIREBASE_STORAGE_BUCKET`
- `DISPLAY_NAME`, `DAILY_CALORIE_GOAL`

## 5. SPA routing

`vercel.json` rewrites all routes to `/index.html` so `/workouts`, `/meals`, etc. work on refresh.

## 6. Post-deploy checklist

- [ ] Open production URL — login screen loads
- [ ] Refresh on `/workouts` — no 404
- [ ] Firebase Console → Auth → add Vercel domain to authorized domains
- [ ] Deploy Firestore rules: `firebase deploy --only firestore:rules`

## 7. Custom domain

Vercel → Domains → add domain → update Firebase Authorized domains.
