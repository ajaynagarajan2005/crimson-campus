# Crimson Campus

A student campus app for INTI International University, Nilai — built with
Flutter (web, Android) and a FastAPI + SQLite backend.

**Live site:** see the GitHub Pages link in this repository's About section.

## Features

- Scroll-driven landing page with glassmorphism, zoom and 3D effects, light and dark themes
- About INTI Nilai, courses and faculties, careers, international community and campus highlights
- Student accounts (sign up / log in) stored in the backend database
- Personalised dashboard: profile, academic snapshot, quick access to 8 campus services
- Virtual student ID with profile photo upload and QR code
- Live campus map (OpenStreetMap) with your location and walking directions
- Shuttle routes with stop maps, departures and alerts
- Timetable, results, attendance, fees, library, clubs, helpdesk tickets, events and announcements

## Run it locally

Backend (port 8000):

```bash
backend\run_backend.bat
```

App (Chrome, port 8090):

```bash
flutter run -d chrome --web-port 8090
```

Optional: set `ORS_API_KEY` (free key from openrouteservice.org) before starting the
backend to enable real walking routes on the campus map.

## About the hosted site

GitHub Pages serves only the Flutter web app. Login and other account features
talk to a backend at `http://localhost:8000`, so they work when the backend is
running on the same computer. To make accounts work for everyone, deploy the
`backend/` folder to a Python host and rebuild with
`--dart-define=API_BASE_URL=https://your-backend.example.com`.

## Project layout

- `lib/` — Flutter app (screens, widgets, theme, state, services)
- `backend/` — FastAPI API, `schema.sql`, SQLite database (not committed)
- `assets/images/` — INTI logo and campus photos
- `test/` — widget tests (`flutter test`)
- `screenshots/` — renders every page to `design/` for review
- `tools/enhance_images.py` — upscales campus photos with EDSR super-resolution

## Credits

Facts: Wikipedia, INTI factsheets and “Why INTI” page, QS TopUniversities.
Map data © OpenStreetMap contributors · map tiles © CARTO.
INTI name, logo and campus photos belong to INTI International University;
this is an unofficial student project.
