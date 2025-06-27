# GiltGenius

A cross-platform (Flutter) app and Python backend for predicting stock returns, visualizing strategies, and exploring technical indicators. **Note:** This public repository does not include proprietary model files, custom themes, or production API keys. For demo/educational use only.

---

## Features
- Predict next-day stock returns for any ticker and date range
- Choose technical indicators (RSI, Bollinger Bands, Moving Averages, etc.)
- Visualize cumulative returns and strategy performance
- Sentiment analysis from real-time news and technical factors
- Portfolio optimizer and backtesting tools
- Works on Android, iOS, Web, and Desktop

---

## Backend (Flask, Python)
- **API Endpoints:**
  - `/predict`, `/backtest`, `/optimize_portfolio`, `/sentiment`, `/list_models`, `/save_model`, `/load_model`, `/delete_model`, `/api/top_gainers`, `/api/top_losers`
- **Swagger/OpenAPI Docs:**
  - Visit `/apidocs` when running the backend to explore and test all endpoints interactively.
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
- **Web build:**
  ```sh
  flutter build web
  # Deploy build/web/ to Netlify, Vercel, or Firebase Hosting
  ```

---

## Deployment & Updates
- **Backend:** Deploy to Render, Railway, AWS, or any Python host. Keep your backend running for live data.
- **Frontend:**
  - **Web:** Deploy to Netlify, Vercel, or Firebase Hosting
  - **Mobile:** Build APK and distribute directly or via Play Store (see notes below)
- **Data & Dates:** The app always fetches the latest stock data and uses the current date by default—no app update required for fresh data.

---

## Security & Privacy
- **Model files (`*.pkl`), API keys, and custom themes/assets are NOT included in this repository.**
- See `.gitignore` for all protected files/folders.
- Do not commit sensitive data or proprietary code.

---

## Screenshots
> _Add screenshots or a demo video here to showcase the UI and features._

---

## Contribution & License
- All dependencies are tracked in `requirements.txt` (backend) and `pubspec.yaml` (frontend)
- PRs and issues welcome!
- **License:** MIT (or add your own)

---

## Disclaimer
**This repository is for demonstration and educational purposes only. The full model, proprietary theme, and production API keys are not included. You may not use this code for commercial purposes without permission.** 
