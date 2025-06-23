import pandas as pd

def add_features(df):
    df['Close'] = pd.to_numeric(df['Close'], errors='coerce')

    # 1. Next-day return (our target)
    df['Return'] = df['Close'].pct_change(fill_method=None).shift(-1)

    # 2. Lag returns
    for lag in [1, 5, 10]:
        df[f'Return_Lag_{lag}'] = df['Close'].pct_change(lag, fill_method=None)

    # 3. Moving Averages
    for window in [5, 10, 20]:
        df[f'MA_{window}'] = df['Close'].rolling(window).mean()

    df = df.dropna()
    return df

if __name__ == "__main__":
    df = pd.read_csv('data/AAPL.csv', index_col=0, parse_dates=True)

    # Convert all numeric columns to float (handles all at once)
    cols_to_convert = ['Open', 'High', 'Low', 'Close', 'Volume']
    for col in cols_to_convert:
        df[col] = pd.to_numeric(df[col], errors='coerce')

    df_feat = add_features(df)
    df_feat.to_csv('data/AAPL_features.csv')
    print("Feature engineering complete. Saved", len(df_feat), "rows.")

