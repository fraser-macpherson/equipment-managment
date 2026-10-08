# DMACP Assets

Equipment check-in/check-out tracker. Static site on **GitHub Pages**, data in **Supabase**, QR codes generated and scanned in the browser.

| File | What it is |
|---|---|
| `index.html` | The whole app (QR generator, QR scanner and Supabase client are built in) |
| `config.js` | Your Supabase URL and anon key - the only file you edit |
| `setup.sql` | Creates the database tables, security rules and check-in/out functions |

---

## 1. Create the Supabase project

1. Sign in at <https://supabase.com> and click **New project**. Pick a name, a strong database password (save it somewhere) and the region closest to you.
2. Wait for the project to finish provisioning.

## 2. Create the database

1. In the project, open **SQL Editor** > **New query**.
2. Paste the entire contents of `setup.sql` and click **Run**. You should see "Success".
3. Check **Table Editor**: you should now have `assets` and `events`.

## 3. Lock it down and create a login

The app is public on the internet, so the database only allows **signed-in users** to read or write. The equipment list holds people's contact details, so keep this step.

1. Go to **Authentication** > **Sign In / Providers** (older dashboards: **Providers** > **Email**). Keep Email enabled and **turn OFF "Allow new users to sign up"**.
2. Go to **Authentication** > **Users** > **Add user** > **Create new user**. Enter an email and password and tick **Auto Confirm User**.
3. Share that login with whoever should use the app (one shared account is fine, or create one per person).

## 4. Connect the app to Supabase

1. Go to **Project Settings** > **API** (newer dashboards may show it under **API Keys** or the **Connect** button).
2. Copy the **Project URL** and the **anon / publishable** key.
3. Open `config.js` and replace the two placeholder values:

```js
window.DMACP_CONFIG = {
  SUPABASE_URL: "https://abcdxyz.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOi..."
};
```

> The anon key is designed to be public, and the security rules from step 2 protect the data. **Never** paste the `service_role` / secret key into this project.

## 5. Publish on GitHub Pages

1. Create a new GitHub repository (e.g. `dmacp-assets`). A public repo works on the free plan.
2. Upload `index.html`, `config.js` and `setup.sql` to the root of the repo (**Add file** > **Upload files**), then commit. `README.md` is optional.
3. Go to **Settings** > **Pages**. Under **Build and deployment**, choose **Deploy from a branch**, branch `main`, folder `/ (root)`, and **Save**.
4. After a minute or two the site is live at `https://YOUR-USERNAME.github.io/dmacp-assets/`.

## 6. Set up the phone

1. Open the Pages URL in **Chrome** (Android) or **Safari** (iPhone) and sign in with the account from step 3.
2. Add it to the home screen: Chrome menu > **Add to Home screen** / Safari Share > **Add to Home Screen**.
3. The first time you scan, tap **Allow** when the browser asks for camera access. If you tapped Block, re-enable it in the browser's site settings.
4. Because the data is online, any phone signed in sees the same list. You are no longer limited to a single device.

## 7. Using the app

1. **Edit Asset** > enter a name and notes > **Add and create QR code**. The item gets an ID such as `A0001`.
2. Print the labels: **Edit Asset** > **Print all QR labels** > **Print**. Or open one item and tap **Save QR image**. Stick the QR on the equipment.
3. **Check Out**: scan the QR, enter name and contact details, save. The item now shows as checked out to that person.
4. **Check In**: scan the QR when it comes back. It returns to storage and the history is recorded.
5. **Library** (book icon): see everything, who has what, search, filter, and tap an item for its history.
6. **Camera icon**: scan any QR to jump straight to that item.
7. No camera? Type the ID (e.g. `A0001`) on the scan screen.

The QR codes only contain the text `DMACP:A0001`, so they keep working even if you move the app or database later.

## 8. Backups and housekeeping

- In the library, **Download backup** saves all items and history as a JSON file. You can also export CSVs from **Table Editor** in Supabase.
- Supabase free-tier projects can be **paused after a period of inactivity**. If the app stops loading, open the Supabase dashboard and restore the project. Check their current limits on the pricing page.
- To change the name, notes or delete an item: open it in the library > **Edit details**.
- Changing the Supabase URL/key later: edit `config.js` in GitHub and commit; Pages updates in a minute.

## Troubleshooting

| Problem | Fix |
|---|---|
| "Setup needed" screen | `config.js` still has the placeholder values |
| "Invalid login credentials" | Check the user exists (step 3) and was auto-confirmed |
| "permission denied" or "new row violates row-level security" | `setup.sql` was not fully run, or you are signed out. Re-run it, then sign in again |
| Camera does not open | Must be the `https://` Pages address; allow camera permission; try the typed-ID box |
| Page shows old version after an update | Hard-refresh, or close and reopen the home-screen app |
| Blank page on GitHub Pages | Pages must be enabled (step 5) and files must be in the repo root |

## Options

- In `index.html`, set `const SWAP=true;` if you want **Check In** to be the button that takes equipment out (name/contact form) and **Check Out** to return it. By default the form appears when equipment leaves storage.
