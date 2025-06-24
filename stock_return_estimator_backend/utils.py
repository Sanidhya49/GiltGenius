import pandas as pd
import yfinance as yf
from sklearn.linear_model import LinearRegression
import pandas_ta as ta

def fetch_and_predict(ticker, start, end, features=None):
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
    df.dropna(inplace=True)

    # Default features if not specified
    all_features = ['Return_Lag_1', 'Return_Lag_5', 'MA_10', 'RSI_14', 'BBL_20', 'BBM_20', 'BBU_20']
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
    model = LinearRegression().fit(X, y)

    df['Predicted_Return'] = model.predict(X)
    df['Strategy_Return'] = df['Predicted_Return'].apply(lambda r: 1 if r > 0 else 0) * df['Return']
    df['Cumulative_Market'] = (1 + df['Return']).cumprod()
    df['Cumulative_Strategy'] = (1 + df['Strategy_Return']).cumprod()

    # Prediction for next day
    latest = df.iloc[-1:][features]
    next_day_pred = model.predict(latest)[0]

    return {
        "predicted_return": round(float(next_day_pred), 4),
        "market_returns": df['Cumulative_Market'].round(2).tolist()[-30:],
        "strategy_returns": df['Cumulative_Strategy'].round(2).tolist()[-30:],
        "summary": {
            "market": round(df['Cumulative_Market'].iloc[-1] * 100 - 100, 2),
            "strategy": round(df['Cumulative_Strategy'].iloc[-1] * 100 - 100, 2),
            "sharpe": round(df['Strategy_Return'].mean() / df['Strategy_Return'].std(), 2)
        },
        "features_used": features
    }
