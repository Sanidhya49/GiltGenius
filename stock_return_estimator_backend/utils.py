import pandas as pd
import yfinance as yf
from sklearn.linear_model import LinearRegression
import pandas_ta as ta
import joblib
import os
import shap

MODEL_DIR = 'models'
LATEST_MODEL = os.path.join(MODEL_DIR, 'latest_model.pkl')

# Save the model to disk
model_cache = {}

def save_model(model_name='latest_model.pkl'):
    global model_cache
    if 'model' in model_cache:
        os.makedirs(MODEL_DIR, exist_ok=True)  # Ensure directory exists
        path = os.path.join(MODEL_DIR, model_name)
        joblib.dump(model_cache['model'], path)
    else:
        raise ValueError('No model trained yet to save.')

def load_model(model_name='latest_model.pkl'):
    path = os.path.join(MODEL_DIR, model_name)
    if not os.path.exists(path):
        raise FileNotFoundError(f'Model {model_name} not found.')
    model_cache['model'] = joblib.load(path)
    return model_cache['model']

def list_models():
    if not os.path.exists(MODEL_DIR):
        return []
    return [f for f in os.listdir(MODEL_DIR) if f.endswith('.pkl')]

def fetch_and_predict(ticker, start, end, features=None, model_name=None):
    # Only keep the date part (YYYY-MM-DD)
    start = start[:10]
    end = end[:10]
    df = yf.download(ticker, start=start, end=end)
    print('Downloaded DataFrame shape:', df.shape)
    print('Columns:', df.columns)
    if isinstance(df.columns, pd.MultiIndex):
        df.columns = df.columns.get_level_values(0)
    if df.empty:
        raise ValueError('No data returned for this ticker and date range.')
    df['Return'] = df['Close'].pct_change().shift(-1)
    df['Return_Lag_1'] = df['Close'].pct_change(1)
    df['Return_Lag_5'] = df['Close'].pct_change(5)
    df['MA_10'] = df['Close'].rolling(10).mean()
    df['RSI_14'] = ta.rsi(df['Close'], length=14)
    bb = ta.bbands(df['Close'], length=20)
    if bb is not None:
        df['BBL_20'] = bb['BBL_20_2.0']
        df['BBM_20'] = bb['BBM_20_2.0']
        df['BBU_20'] = bb['BBU_20_2.0']
    else:
        df['BBL_20'] = df['BBM_20'] = df['BBU_20'] = None
    # --- New indicators ---
    macd = ta.macd(df['Close'])
    if macd is not None:
        df['MACD'] = macd['MACD_12_26_9']
        df['MACD_signal'] = macd['MACDs_12_26_9']
        df['MACD_hist'] = macd['MACDh_12_26_9']
    else:
        df['MACD'] = df['MACD_signal'] = df['MACD_hist'] = None
    stoch = ta.stoch(df['High'], df['Low'], df['Close'])
    if stoch is not None:
        df['STOCH_k'] = stoch['STOCHk_14_3_3']
        df['STOCH_d'] = stoch['STOCHd_14_3_3']
    else:
        df['STOCH_k'] = df['STOCH_d'] = None
    df['ATR_14'] = ta.atr(df['High'], df['Low'], df['Close'], length=14)
    df.dropna(inplace=True)

    # Default features if not specified
    all_features = [
        'Return_Lag_1', 'Return_Lag_5', 'MA_10', 'RSI_14',
        'BBL_20', 'BBM_20', 'BBU_20',
        'MACD', 'MACD_signal', 'MACD_hist',
        'STOCH_k', 'STOCH_d', 'ATR_14'
    ]
    if features is None:
        features = all_features
    else:
        # Only keep valid features
        features = [f for f in features if f in all_features]
        if not features:
            features = all_features

    print('Features requested:', features)
    print('DataFrame columns after feature engineering:', df.columns)

    X = df[features]
    y = df['Return']

    # Model logic
    global model_cache
    if model_name:
        # Try to load model if specified
        try:
            model = load_model(model_name)
        except Exception:
            model = LinearRegression().fit(X, y)
            model_cache['model'] = model
            save_model(model_name)
    else:
        model = LinearRegression().fit(X, y)
        model_cache['model'] = model
        save_model('latest_model.pkl')

    # Always autosave the model under the loaded model's name after prediction
    if model_name:
        save_model(model_name)

    df['Predicted_Return'] = model.predict(X)
    df['Strategy_Return'] = df['Predicted_Return'].apply(lambda r: 1 if r > 0 else 0) * df['Return']
    df['Cumulative_Market'] = (1 + df['Return']).cumprod()
    df['Cumulative_Strategy'] = (1 + df['Strategy_Return']).cumprod()

    # Prediction for next day
    latest = df.iloc[-1:][features]
    next_day_pred = model.predict(latest)[0]

    # SHAP explanation for the latest prediction
    try:
        explainer = shap.Explainer(model, X)
        shap_values = explainer(latest)
        shap_dict = dict(zip(features, shap_values.values[0]))
    except Exception as e:
        shap_dict = {f: 0.0 for f in features}  # fallback if SHAP fails

    return {
        "predicted_return": round(float(next_day_pred), 4),
        "market_returns": df['Cumulative_Market'].round(2).tolist()[-30:],
        "strategy_returns": df['Cumulative_Strategy'].round(2).tolist()[-30:],
        "summary": {
            "market": round(df['Cumulative_Market'].iloc[-1] * 100 - 100, 2),
            "strategy": round(df['Cumulative_Strategy'].iloc[-1] * 100 - 100, 2),
            "sharpe": round(df['Strategy_Return'].mean() / df['Strategy_Return'].std(), 2)
        },
        "features_used": features,
        "shap_values": shap_dict
    }
