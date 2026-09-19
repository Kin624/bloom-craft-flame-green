# bloom-craft-flame-green

A full-stack web application workspace scaffolded by **Grok Build** — xAI's AI-powered app builder. Built on a modern React + Node.js stack and deployed to Vercel.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | [TanStack Start](https://tanstack.com/start) (React 19 + SSR) |
| Routing | TanStack Router |
| Styling | Tailwind CSS v4 |
| UI Components | Radix UI primitives + shadcn/ui |
| State Management | Zustand |
| Data Fetching | TanStack Query |
| Forms | React Hook Form + Zod |
| Auth | [Better Auth](https://www.better-auth.com/) |
| Database | PostgreSQL via Kysely + PGlite |
| Build Tool | Vite 8 |
| Language | TypeScript 5 |
| Testing | Playwright |
| Deployment | Vercel |

---

## Project Structure

```
.
├── src/
│   ├── routes/         # TanStack file-based routes
│   ├── lib/            # Shared utilities (auth, db, app-data)
│   └── styles.css      # Global styles (Tailwind entry)
├── server/             # Server middleware (platform chrome)
├── scripts/            # Build & dev helper scripts
├── migrations/         # Database migration SQL files
├── public/             # Static assets
├── artifacts/          # Grok project files (persisted across conversations)
├── attachments/        # User-provided file attachments
├── screenshots/        # QA screenshots (generated during testing)
├── .grok/              # Grok Build agent skills & references
├── AGENTS.md           # Grok Build agent specification
├── AGENTS.project.md   # Project-level agent instructions
├── startup.sh          # Dev server restart contract (required by platform)
├── vite.config.ts      # Vite configuration
└── tsconfig.json       # TypeScript configuration
```

---

## Getting Started

### Prerequisites

- **Node.js 22+**
- **npm**

### Install Dependencies

```bash
npm install
```

### Development

```bash
npm run dev
```

The dev server starts at `http://localhost:8080`.

### Build for Production

```bash
npm run build
```

### Preview Production Build

```bash
npm run preview
```

### Other Scripts

| Command | Description |
|---|---|
| `npm run typecheck` | Run TypeScript type checking |
| `npm run lint` | Run ESLint |
| `npm run format` | Format code with Prettier |
| `npm run db:migrate` | Run database migrations |
| `npm test` | Run unit tests |

---

## Database & Auth

Both database and authentication are **opt-in** and off by default. This workspace uses:

- **Auth OFF / DB OFF** (default): client-only state via `localStorage` / Zustand — suitable for games, calculators, landing pages.
- **Auth OFF / DB ON**: shared persistent data with unowned rows — no user accounts needed.
- **Auth ON**: full per-user accounts via Better Auth, with `authMiddleware` enforced on all server functions and queries scoped to the verified `userId`.

The platform injects `DATABASE_URL` and auth credentials at deploy time. **Do not create a `.env` file** — use `VITE_`-prefixed variables for anything that needs to reach the browser.

---

## Deployment

This app is deployed to **Vercel**. Things to keep in mind for production compatibility:

- No runtime filesystem writes
- No server-only Node APIs imported at module level
- No hard-coded `localhost` URLs, ports, or secrets
- Dev-only dependencies must not be imported in production code

---

## Agent Specification

This workspace is designed to be built and extended by the **Grok Build** AI agent. The agent follows:

- **`AGENTS.md`** — the full sandbox contract and execution loop (environment rules, scaffolding requirements, QA process, communication rules).
- **`AGENTS.project.md`** — project-specific instructions; user-provided files are mounted at `/workspace/artifacts`.
- **`.grok/skills/`** — skill files the agent consults before building specific surfaces (UI, games, auth, data, image generation).
- **`.grok/references/`** — deeper reference docs (deployment target, auth/db wiring, scaffold templates, hibernate/revive, browser QA).

---

## License

Private repository. All rights reserved.
