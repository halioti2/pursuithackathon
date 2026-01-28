# Snow Shoveling Jobs — MVP

A minimal static prototype for posting and managing snow shoveling jobs.

## What this contains
- `index.html`: static Bootstrap-based UI to create and view jobs and simple worker profile examples.
- `css/styles.css`: minimal styles.
- `js/app.js`: app logic using localStorage to persist jobs and user profiles (MVP).
- `PRD.md`: product requirements document.

## Tech stack
- HTML + CSS
- Bootstrap 5 (via CDN)
- Vanilla JavaScript (ES6)

## Git setup (basic)
Run these commands from the repo root (macOS, zsh):

```bash
git init
git add .
git commit -m "chore: initial scaffold for snow shoveling jobs app"
# Add a remote if you have one:
# git remote add origin git@github.com:yourusername/snow_app.git
# git push -u origin main
```

Recommended branch strategy: `main` (stable) + feature branches (`feature/XXX`) + PRs.

## Run locally
This is a static site. You can open `index.html` in your browser directly or run a simple static server.

Simple Python server:

```bash
# Python 3
python3 -m http.server 8000
# then open http://localhost:8000
```

## Notes
This is an MVP scaffold. For production you'll need a backend (API + DB), authentication, and security features (see `PRD.md`).
