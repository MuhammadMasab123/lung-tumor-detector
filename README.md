# Lung Tumor Detector — Complete Project

Two folders inside. The app is the front end, the backend is the brain.
They work together: the app sends a scan to the backend, the backend's AI
analyses it and sends the result back.

## What's inside

- `lung-tumor-detector-app/` — the Flutter mobile app (login, upload scan,
  results with verdict + heatmap, history, doctor finder, profile).
- `lung-tumor-detector/` — the original project: FastAPI backend with the AI
  (ResNet50), plus the original React web frontend.

## Credits

The backend and the React web frontend in `lung-tumor-detector/` come from
the original LungTumorDetector project by Hasham Khan:
https://github.com/hashamkhan11/LungTumorDetector

The Flutter mobile app in `lung-tumor-detector-app/` is a mobile rebuild of
that system, written in simple Dart/Flutter with the same features.

## You need first

- Python 3.11+ installed (python.org — tick "Add Python to PATH").
- Flutter installed (flutter.dev) for the mobile app.
- Node.js 18+ only if you also want the original React web frontend.

## Step 1 — Set up the backend (first time only)

In a terminal, go into the `lung-tumor-detector` folder and run:

```
.\setup.bat
```

This installs the Python packages and downloads the two AI model files
from HuggingFace. It downloads a lot (PyTorch + TensorFlow), so give it
10–20 minutes and don't close the window.

## Step 2 — Start the backend (every time you use the app)

In a terminal inside the `lung-tumor-detector` folder:

```
python main.py
```

Leave that window open. You should see `Uvicorn running on http://0.0.0.0:8000`.

Check it in your browser: http://127.0.0.1:8000/health
It should say `"status": "healthy"` and `"model_status": "loaded"`.

If `python` is not recognized, use `py main.py` instead.

## Step 3 — Run the mobile app

In a second terminal, go into the `lung-tumor-detector-app` folder:

```
flutter pub get
flutter run -d chrome
```

The app opens in Chrome. Log in, upload a chest X-ray, tap "Analyse with AI".

On a real phone instead of Chrome: `flutter run` and pick your phone.
Then in the app go to Profile and set the Backend URL to your PC's Wi-Fi
address, e.g. `http://192.168.1.5:8000` (find it with `ipconfig` on Windows).

## If the app says "Backend not reachable"

The backend (Step 2) is not running. Start it with `python main.py`
and tap Retry in the app.

## Notes

- Login in the mobile app is a local session for now (no Firebase
  configured). It just saves your name and email on the device.
- The app is a screening aid only. Results must be reviewed by a
  qualified doctor — never a final diagnosis on its own.
