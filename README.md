# Stock Return Estimator

A cross-platform (Flutter) app and Python backend for predicting stock returns, visualizing strategies, and exploring technical indicators.

---

## Features
- Enter any stock ticker and date range
- Choose technical indicators (RSI, Bollinger Bands, Moving Averages, etc.)
- Backend fetches historical data, engineers features, and predicts next-day returns
- Visualizes cumulative returns and strategy performance
- Works on Android, iOS, Web, and Desktop

---

## Project Structure

```
stock-return-estimator/
├── stock_return_estimator_backend/   # Flask backend (API, ML, feature engineering)
│   ├── app.py
│   ├── utils.py
│   └── requirements.txt
├── stock_return_estimator_app/       # Flutter frontend (UI, charts, user input)
│   ├── lib/
│   ├── pubspec.yaml
│   └── README.md
├── ... (other scripts, .gitignore, etc.)
```

---

## Backend (Flask, Python)
- **API Endpoint:** `POST /predict`
  - **Body:** `{ "ticker": "AAPL", "start": "YYYY-MM-DD", "end": "YYYY-MM-DD", "features": ["RSI_14", ...] }`
  - **Returns:** Predicted return, cumulative returns, strategy stats, features used
- **Key dependencies:** See `stock_return_estimator_backend/requirements.txt`
- **How to run:**
  ```sh
  cd stock_return_estimator_backend
  python -m venv venv
  source venv/bin/activate  # or venv\Scripts\activate on Windows
  pip install -r requirements.txt
  python app.py
  ```

---

## Frontend (Flutter)
- **Key files:** `lib/main.dart`, `lib/pages/home_page.dart`, `lib/pages/result_page.dart`
- **How to run:**
  ```sh
  cd stock_return_estimator_app
  flutter pub get
  flutter run
  ```
- **Dependencies:** See `pubspec.yaml` (uses `http`, `fl_chart`, `intl`, etc.)

---

## Development & Contribution
- All dependencies are tracked in `requirements.txt` (backend) and `pubspec.yaml` (frontend)
- The `/venv` and build artifacts are gitignored
- PRs and issues welcome!

---

## License
MIT (add your license here) 