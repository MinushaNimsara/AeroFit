# One-time Vercel setup (2 minutes)

GitHub Actions can deploy for you after you add **3 secrets** once.

## Step 1 — Create a Vercel token

1. Open [vercel.com/account/tokens](https://vercel.com/account/tokens)
2. Click **Create Token** → name it `AeroFit-GitHub` → copy the token

## Step 2 — Get Project ID and Org ID

1. Open [vercel.com](https://vercel.com) → your **aero-fit-slul** project
2. Go to **Settings → General**
3. Copy **Project ID**
4. Copy **Team / User ID** (under General → this is your Org ID)

## Step 3 — Add GitHub secrets

1. Open [github.com/MinushaNimsara/AeroFit/settings/secrets/actions](https://github.com/MinushaNimsara/AeroFit/settings/secrets/actions)
2. Click **New repository secret** and add:

| Name | Value |
|------|--------|
| `VERCEL_TOKEN` | token from Step 1 |
| `VERCEL_ORG_ID` | Team/User ID from Step 2 |
| `VERCEL_PROJECT_ID` | Project ID from Step 2 |

## Step 4 — Deploy

Push to `main` or run **Actions → Deploy to Vercel → Run workflow**.

The workflow uses the committed `web/` build — no Flutter install on the server.

## After code changes

```powershell
flutter build web --release --base-href /
Copy-Item -Path build\web\* -Destination web\ -Recurse -Force
git add web/
git commit -m "Update web build"
git push origin main
```
