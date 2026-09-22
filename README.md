# Homely V8

Homely is a household routine and home planner connected to Supabase.

## V8 includes
- Daily / weekly / monthly / custom recurring chores
- Start dates and multiple weekly days
- Per-chore reminder enable/disable and reminder time
- Quiet hours
- Browser/PWA reminder notifications while Homely is running
- Personalized greeting / display name
- Today's progress and reset
- Calendar month navigation and selected-day schedule
- Room-level counts and room detail
- Progress history and streak
- Cleaning Mode
- Shopping / supplies list
- Home maintenance list
- Supabase cloud sync

## Upload
Replace the current GitHub Pages files with:
- index.html
- sw.js
- manifest.webmanifest
- mjb-logo.png

## Supabase
1. Keep the existing Homely schema.
2. Run `SUPABASE-V8-MIGRATION.sql` once in Supabase SQL Editor.
3. Never put a secret/service_role key in the website.

## Notification limitation
The browser notification engine checks reminders while the Homely page/PWA is running. True OS push reminders while the app is fully closed require a Web Push/VAPID server or Supabase Edge Function, which can be added as a separate deployment step.
