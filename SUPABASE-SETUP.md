# Homely — Supabase Setup

This version of Homely is connected to the Supabase project configured in `index.html` using a **publishable key**. The publishable key is safe for browser use; never put a `sb_secret_` or `service_role` key in the website.

## 1. Create the database tables

Open **Supabase → SQL Editor → New query**, paste the contents of `supabase-schema.sql`, and click **Run**.

The script creates:
- `profiles`
- `households`
- `household_members`
- `rooms`
- `chores`
- `chore_completions`

It also enables Row Level Security and creates policies so signed-in household members can access only their household data.

## 2. Authentication

In Supabase, open **Authentication → Providers → Email** and keep Email enabled.

For the first Homely test, email/password is enough. If email confirmation is enabled, create an account and confirm the email before signing in.

## 3. Use the updated website

Upload all files from this Homely folder to your GitHub Pages repository. The browser version will show **Settings → Cloud Sync**.

- **Create Account** creates a Supabase Auth account.
- **Sign In** creates/loads the user's Homely household.
- The first sign-in can upload the existing local chores if the cloud household is empty.
- Later changes are synced to Supabase.
- A second device can sign in with the same account and load the cloud data.

## Security note

The Supabase URL and `sb_publishable_...` key are intentionally used in the browser. This is normal for Supabase client applications. Security comes from Authentication + Row Level Security. Never place a database password, `sb_secret_...`, or `service_role` key in `index.html`.
