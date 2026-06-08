# Deploy AeroFit (Flutter Web PWA) on Vercel

## Prerequisites

- Git repo connected to Vercel
- Firebase Web app configured (`docs/FIREBASE_WEB_INIT.md`)
- FlutterFire **or** Vercel env vars for Firebase (see below)

## 1. Project settings in Vercel

| Setting | Value |
|---------|--------|
| Framework Preset | **Other** |
| Root Directory | `.` (repo root) |
| Install Command | *(from `vercel.json`)* `bash scripts/vercel-install.sh` |
| Build Command | *(from `vercel.json`)* `bash scripts/vercel-build.sh` |
| Output Directory | `build/web` |

`vercel.json` at the repo root sets these automatically when you import the project.

## 2. Environment variables (Production)

Add in Vercel → Settings → Environment Variables:

**Firebase (if not committing `firebase_options.dart`):**

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_STORAGE_BUCKET`

**App:**

- `DISPLAY_NAME` = `Minusha`
- `DAILY_CALORIE_GOAL` = `2000`
- `FOOD_VISION_API_URL` = `https://your-python-api.com/analyze-food`

## 3. Why `vercel.json` rewrites matter

Flutter Web + **go_router** uses client-side routes (`/meals`, `/workouts`, etc.). A direct visit or refresh on `/meals` would 404 without a rewrite to `index.html`.

The rewrite rule sends unknown paths to `index.html` while **excluding** static assets (`assets/`, `canvaskit/`, `main.dart.js`, service worker, icons, manifest).

## 4. Deploy

```bash
# CLI (optional)
npm i -g vercel
vercel --prod
```

Or push to `main` with Git integration.

First build takes ~8–15 minutes (Flutter SDK clone). Later builds use Vercel cache if `FLUTTER_HOME` persists.

## 5. Post-deploy checklist

- [ ] Open `https://your-app.vercel.app` — Dashboard loads
- [ ] Navigate to `/meals` → refresh page → **no 404**
- [ ] Chrome → Install App banner or address bar install icon
- [ ] Firebase Auth → add Vercel domain to authorized domains
- [ ] Firestore rules deployed

## 6. Local production build (test before deploy)

```powershell
flutter build web --release --base-href /
npx serve build/web
```

Test deep links: `http://localhost:3000/workouts`.

## 7. Custom domain

Vercel → Domains → add domain → update Firebase Authorized domains and Auth redirect URLs.
