---
name: mpfh-dev
description: Use when developing, running, or debugging MPFH locally
---

# MPFH Local Development

## Quick Start

```bash
# Install dependencies
npm install

# Start dev server
npm run dev
```

App runs at `http://localhost:5173`.

## Project Structure

```
MPFH/
├── src/
│   ├── App.vue              # Main app (license check, routing)
│   ├── components/
│   │   ├── RecordButton.vue  # Voice recording button
│   │   ├── QRCodeDisplay.vue # Result display + URL copy
│   │   ├── SettingsModal.vue # Settings (instruction, replies count)
│   │   └── LicenseModal.vue  # License key input
│   ├── composables/
│   │   ├── useRecording.ts   # Web Speech API wrapper
│   │   ├── useSettings.ts    # Settings persistence (localStorage)
│   │   └── useLicense.ts     # License validation (CRC16)
│   └── types/
├── backend/
│   ├── handler.py            # Cloud Function (Yandex S3)
│   └── openapi.yaml          # API Gateway spec
└── dist/                     # Build output
```

## Key Features

### Voice Recording (`useRecording.ts`)
- Uses Web Speech API (`webkitSpeechRecognition`)
- Language: `ru-RU`
- Continuous mode, no interim results
- Each recognized phrase added to `replies` array

### License System (`useLicense.ts`)
- Format: `MPFH-YYYYMMDD-XXXX-XXXX`
- CRC16 checksum for validation
- Expiration date embedded in key
- Stored in localStorage

### Settings (`useSettings.ts`)
- `instruction` — text shown to viewers
- `repliesCount` — number of replies to collect before showing result

## Debugging Tips

### Speech Recognition Issues
- Must run over HTTPS or localhost
- Chrome has best support for `ru-RU`
- Check browser console for `SpeechRecognition` errors

### API Calls
- Backend expects POST to `/save` with `{ instruction, replies }`
- Response page served at GET `/`
- Mock backend locally if needed

### License Testing
- Valid key format: `MPFH-20261231-A1B2-C3D4`
- Use `validateKeyFormat()` in browser console to test
- Keys stored in localStorage under `mpfh-license-key`

## Build Commands

```bash
npm run dev       # Dev server with HMR
npm run build     # Type check + production build
npm run preview   # Preview production build locally
```

## Common Issues

| Issue | Solution |
|-------|----------|
| Speech recognition not working | Use Chrome, ensure HTTPS/localhost |
| CORS errors in dev | Backend must have CORS headers |
| License not persisting | Check localStorage in DevTools |
| Build fails | Run `npm install` first |
