# NFL Win Total Draft — setup guide

You're deploying 3 free services that talk to each other:
**Supabase** (the shared database) → **your website** (Vercel) → **GitHub Actions** (the weekly auto-update).

Total time: ~30–45 minutes, one time only.

---

## Step 1 — Create the database (Supabase)

1. Go to [supabase.com](https://supabase.com) → sign up (free) → "New project".
2. Once it's created, go to the **SQL Editor** tab → "New query".
3. Paste in the entire contents of `schema.sql` from this folder → click **Run**.
   This creates your tables and seeds all 32 teams with their win-total lines.
4. Go to **Project Settings → API**. You'll need two values from this page:
   - **Project URL** (looks like `https://abcxyz.supabase.co`)
   - **anon public** key (a long string)

---

## Step 2 — Connect the website to it

1. Open `index.html` in a text editor.
2. Near the top of the `<script>` section, replace:
   ```js
   const SUPABASE_URL = 'YOUR_SUPABASE_URL';
   const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
   ```
   with the two values from Step 1.4.
3. Save the file.

---

## Step 3 — Put it online (Vercel)

The easiest path if you're not already a git user:

1. Go to [vercel.com](https://vercel.com) → sign up free (you can use your GitHub account to sign in, which also sets you up for Step 4).
2. Create a new GitHub repository (on github.com, click "New repository", name it e.g. `nfl-win-draft`) and upload this whole folder to it — GitHub's web UI lets you drag-and-drop files if you don't want to use git commands.
3. In Vercel, click "Add New → Project", pick that repository, leave all settings default, click **Deploy**.
4. Vercel gives you a live URL like `nfl-win-draft.vercel.app` — that's the link you send your friends.

*(Netlify works identically if you prefer it — same drag-and-drop-a-repo flow.)*

---

## Step 4 — Turn on the weekly auto-update (GitHub Actions)

1. In Supabase: **Project Settings → API** → copy the **service_role** key (different from the anon key — keep this one secret, never put it in the website code).
2. In your GitHub repository: **Settings → Secrets and variables → Actions → New repository secret**. Add two secrets:
   - `SUPABASE_URL` → your project URL from Step 1.4
   - `SUPABASE_SERVICE_KEY` → the service_role key from this step
3. That's it — `.github/workflows/update-wins.yml` is already in the repo. It will run automatically every **Tuesday at 9am ET**, pull each team's current win total from ESPN, and write it into your database. Everyone's site updates within seconds since it's reading from the same live database.
4. To test it immediately rather than waiting for Tuesday: go to your repo's **Actions** tab → "Update NFL win totals" → "Run workflow".

---

## How it works, in short

- **Supabase** holds the one shared copy of the draft board and win totals (Postgres database + a free realtime layer that pushes changes to every open browser tab instantly).
- **index.html** is a plain webpage — no build step — that reads/writes to Supabase directly from the browser.
- **GitHub Actions** is a free scheduler. Every Tuesday it spins up a tiny throwaway computer, runs `update-wins.js`, and shuts back down. That script hits ESPN's public (unofficial, no-key-needed) score API and writes each team's real win count into your database.

## Things worth knowing

- **No login system.** Anyone with the site link can edit any pick. Fine for 3 friends — just don't post the link somewhere public.
- **ESPN's API is unofficial.** It's widely used and stable, but it could change format without notice. If the Tuesday run ever stops updating wins, check the Action's log (repo → Actions tab) for the error first.
- **Free tier limits.** Supabase's free tier and Vercel's free tier are both far more generous than 3 friends checking a page weekly will ever need.
