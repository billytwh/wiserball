# Wiser Sport (Web)

Referee console for Wiser Sport matches. Built as a client-side React app with local persistence.

## Features
- Competition modes: Single (5 balls), Double (6 balls), Team (7 balls)
- Ball states: Contesting → First-Locked → Second-Locked → Struck-Out
- Match page: ball tracking, rescue relationships, pending rescue list, scoring, and result modal
- Tools page: referee utilities (fouls, timers, out-of-bounds checklist)
- Local persistence via `localStorage` (single-device)
- Revision mode:
  - Edit/delete hit records and rebuild the match state
  - Correct positioning records and rebuild the match state

## Tech Stack
- React 18 + TypeScript
- Vite
- Tailwind CSS
- zustand (state store)
- react-router-dom

## Development
```bash
cd wiser_sport_web
npm install
npm run dev
```

## Build
```bash
cd wiser_sport_web
npm install
npm run build
```

Output: `wiser_sport_web/dist/`

## Deployment (Hostinger Node.js App Hosting)
This repo includes a simple Express static server with SPA fallback, so routes like `/tools` still work after refresh.

1. Upload the project source (not `dist` only). Ensure `package.json` is at the archive root.
2. Set commands:
   - Build: `npm ci && npm run build`
   - Start: `npm start`
3. App listens on `process.env.PORT`.

## Local Storage
- Key: `wiserSport.web.gameState.v1`
- Saved data includes ball states, hits, fouls, positioning history, discussion counts, and pending rescues.

## Project Structure
- `src/pages/Match.tsx`: match workflow and main UI
- `src/lib/wiser.ts`: rules engine and state rebuild logic
- `src/store/gameStore.ts`: zustand store + persistence
- `server.js`: Express static server for production hosting
