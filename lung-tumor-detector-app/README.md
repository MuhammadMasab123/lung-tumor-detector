# Lung Tumor Detector — Flutter Mobile App

A mobile version of the **LungTumorDetector** project
(React + FastAPI web app), rebuilt in simple Dart/Flutter code — plain
`StatefulWidget`s, one file per screen, no Riverpod/Bloc/GetX or other
complex state management. Same features, same content, new beautiful UI.

## What it does

- **Login / Register** — email + password forms with validation and a
  password-strength meter (same rules as the web app).
- **Home / Upload Scan** — pick a chest X-ray or CT scan from the gallery
  or camera, preview it, and analyse it with AI (ResNet50).
- **Results** — original scan + Grad-CAM heatmap, verdict box
  (Cancerous / Non-Cancerous / Uncertain), confidence %, risk level,
  cancer probability, lung-gate %, confidence bar, medical advice and the
  medical disclaimer. A **Find Doctor** button appears when the result is
  Cancerous.
- **History** — past scans saved on the device, with stats, filters,
  swipe-to-delete and clear-all. Tap an entry to view it again.
- **Doctor Finder** — uses your location + OpenStreetMap (Overpass API)
  to list nearby hospitals, clinics and doctors, sorted by distance, with
  radius picker, filters, deterministic appointment slots, call and
  Google Maps directions.
- **Profile** — name/email, medical profile (age, smoking history,
  exposure), backend API URL setting, sign out, medical disclaimer.

## How to run it

```bash
flutter pub get
flutter run
```

Pick a device (Chrome for web, or a connected phone/emulator for Android).

## Pointing it at the backend

The app talks to the FastAPI backend from the original repo
(`python main.py` in `~/workspace/lung-tumor-detector`, port 8000).

- **Android emulator:** the default URL `http://10.0.2.2:8000` already
  points at your PC's localhost — nothing to change.
- **Real phone:** open **Profile → Backend Connection** and set the URL
  to your PC's LAN IP, e.g. `http://192.168.1.5:8000` (your phone and PC
  must be on the same Wi-Fi).
- **Web (Chrome):** set the URL to `http://localhost:8000`.

## Honest limits — read before expecting real detection

1. **The backend must be running.** The app is only the front end; all
   AI analysis happens in the FastAPI server (`main.py`).
2. **The trained model files are missing from the repo.** The backend
   looks for `model/lung_classifier_model.pth` and
   `model/lung_resnet50_stage1_safe.keras` — neither is in the GitHub
   repo. Without them the backend starts but `/predict` returns
   "Cancer model not loaded". Get those two files from the project owner
   and drop them into the `model/` folder of the original repo.
3. **Login is a local session.** Firebase is not configured in this app
   (no `google-services.json`), so sign-in just saves your name/email on
   the device. Real Firebase Auth can replace the session service later
   without changing the screens. The backend likewise only enforces
   Firebase tokens when Firebase is configured server-side.
4. **PDF report is not included.** The web app has a "PDF Report"
   button; this build shows the same report on screen but does not
   export a PDF yet.

## Medical disclaimer

This AI tool is a screening aid only and does not replace professional
medical diagnosis. All results must be reviewed by a qualified
healthcare professional before any clinical decision is made.
