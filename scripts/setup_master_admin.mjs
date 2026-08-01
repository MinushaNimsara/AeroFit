/**
 * One-time bootstrap: creates (or signs in) a master admin Auth user and
 * writes users/{uid} with role "master_admin".
 *
 * Usage (PowerShell):
 *   $env:MASTER_ADMIN_EMAIL="you@example.com"
 *   $env:MASTER_ADMIN_PASSWORD="YourSecurePassword123"
 *   $env:MASTER_ADMIN_NAME="Platform Admin"   # optional
 *   node scripts/setup_master_admin.mjs
 */

const API_KEY = 'AIzaSyB7-Zjv0tYvxrlCmpIgJSb4Yyjj1vhPfnE';
const PROJECT_ID = 'aerofit-303c9';

const email = process.env.MASTER_ADMIN_EMAIL?.trim();
const password = process.env.MASTER_ADMIN_PASSWORD;
const displayName = process.env.MASTER_ADMIN_NAME?.trim() || 'Platform Admin';

if (!email || !password) {
  console.error(
    'Set MASTER_ADMIN_EMAIL and MASTER_ADMIN_PASSWORD environment variables.',
  );
  process.exit(1);
}

if (password.length < 6) {
  console.error('MASTER_ADMIN_PASSWORD must be at least 6 characters.');
  process.exit(1);
}

async function signUp() {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password,
        returnSecureToken: true,
      }),
    },
  );
  const data = await res.json();
  if (!res.ok) {
    if (data.error?.message === 'EMAIL_EXISTS') return signIn();
    throw new Error(data.error?.message ?? 'Sign up failed');
  }
  return data;
}

async function signIn() {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password,
        returnSecureToken: true,
      }),
    },
  );
  const data = await res.json();
  if (!res.ok) {
    throw new Error(data.error?.message ?? 'Sign in failed');
  }
  return data;
}

async function updateDisplayName(idToken, name) {
  await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:update?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        idToken,
        displayName: name,
        returnSecureToken: false,
      }),
    },
  );
}

async function writeMasterAdminProfile(uid, idToken) {
  const now = new Date().toISOString();
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}` +
    `/databases/(default)/documents/users/${uid}` +
    `?currentDocument.exists=true&updateMask.fieldPaths=displayName` +
    `&updateMask.fieldPaths=role&updateMask.fieldPaths=createdAt`;

  const createUrl =
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}` +
    `/databases/(default)/documents/users?documentId=${uid}`;

  const body = {
    fields: {
      displayName: { stringValue: displayName },
      role: { stringValue: 'master_admin' },
      createdAt: { timestampValue: now },
    },
  };

  let res = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (res.status === 404) {
    res = await fetch(createUrl, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${idToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });
  }

  const data = await res.json();
  if (!res.ok) {
    throw new Error(data.error?.message ?? 'Firestore write failed');
  }
}

async function main() {
  console.log(`Setting up master admin for ${email}...`);
  const auth = await signUp();
  const uid = auth.localId;
  const idToken = auth.idToken;

  await updateDisplayName(idToken, displayName);
  await writeMasterAdminProfile(uid, idToken);

  console.log('');
  console.log('Master admin ready.');
  console.log(`  UID:   ${uid}`);
  console.log(`  Email: ${email}`);
  console.log(`  Role:  master_admin`);
  console.log('');
  console.log('Sign in at: /master-admin');
}

main().catch((err) => {
  console.error('Setup failed:', err.message ?? err);
  process.exit(1);
});
