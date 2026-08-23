# A+ Study Hub — Agent Instructions

## What this is
Single-file study app (`index.html`) for CompTIA A+ 220-1201 / 220-1202. Deployed live at **https://kaijuchu.github.io**. Repo: `Kaijuchu/Kaijuchu.github.io`.

## Commands
| Command | What it does |
|---|---|
| `start-app.bat` | Launches local server on `http://localhost:8765` (browser opens automatically) |
| `powershell serve.ps1` | Same as above, in current terminal |
| `powershell sync.ps1` | Stages all changes, writes a descriptive commit (auto-detects quiz additions, styling, AI features, labs), pushes to `origin/main` |
| `powershell github-sync.bat` | Menu: (1) initial setup, (2) sync now, (3) enable auto-sync, (4) disable |
| `powershell autostart.bat` | Manage silent background server at login |

## Architecture
- **One file**: everything lives in `index.html` — HTML, CSS, JS. No build step, no dependencies.
- **Local server**: `serve.ps1` uses .NET `HttpListener` on port 8765. Only needed for local testing (AI calls require localhost, not `file://`).
- **Sync**: `sync.ps1` inspects the `index.html` diff to generate human-readable commit messages like "Update study app: 3 new questions, styling (+42/-7)".
- **Auto-sync**: `sync-loop.ps1` runs `sync.ps1 -Quiet` every 15 minutes as a background process.

## Adding Questions
Questions are defined as JS objects in `index.html` with `d` (question text) and options. The sync script detects new questions by matching `\{\s*d:"` patterns in the diff.

## Style Conventions
- All UI strings, question text, and explanations are in `index.html`.
- CSS uses CSS custom properties in `:root` (dark theme) and `body.light` (light theme).
- Dark theme is the default; light mode toggled via `body.light`.
- Animated nav icons use inline SVG with CSS keyframe animations — don't remove the `#nav .ico svg` elements.
- AI chat uses `callGemini` / `callClaude` functions — API keys are stored in `localStorage`, never hardcode them.

## Deployment
Pushing to `origin/main` triggers a GitHub Pages deploy to https://kaijuchu.github.io (usually within ~1 minute). No CI/CD config needed.

## Local-Only Files (gitignored)
- `aplus-progress-*.json` — user progress data
- `*.mp4` — lab video assets

## Do Not
- Add a `package.json` or build tooling — this is a single-file app by design.
- Commit progress JSON files or videos.
- Change the branch name from `main`.
- Hardcode API keys — they belong in localStorage or a local config the user sets.
