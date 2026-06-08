# PWA setup (AeroFit)

## 1. `web/manifest.json`

Already configured with:

- `display: standalone` — opens like a native app
- `theme_color` / `background_color` matching dark UI
- Maskable + standard icons under `web/icons/`
- App shortcuts to `/meals` and `/workouts`

After changing icons or name, rebuild: `flutter build web`.

## 2. `web/index.html`

Includes:

- `<link rel="manifest" href="manifest.json">`
- Apple meta tags for iOS home screen
- **Install banner** — listens for `beforeinstallprompt`, shows “Install App”
- Service worker registration for `flutter_service_worker.js` (generated on build)

## 3. Install criteria (browsers)

Chrome/Edge will offer install when:

- Served over **HTTPS** (or `localhost` for dev)
- Valid `manifest.json` with 192px + 512px icons
- Registered service worker
- User engagement heuristics met

Run locally:

```bash
flutter run -d chrome
```

Production:

```bash
flutter build web --release
# Deploy build/web/ to Firebase Hosting, Vercel, Netlify, etc.
```

## 4. Customize branding

Replace files in `web/icons/` and `web/favicon.png`. Keep sizes 192 and 512 (plus maskable variants).

## 5. `flutter build web` base href

If hosting in a subpath, use:

```bash
flutter build web --base-href /aerofit/
```

## 6. iOS Safari

There is no `beforeinstallprompt` on iOS. Users use **Share → Add to Home Screen**. The apple-touch-icon and `apple-mobile-web-app-*` meta tags support that flow.
