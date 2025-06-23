import yfinance as yf
import pandas as pd

def fetch_data(ticker, start, end):
    df = yf.download(ticker, start=start, end=end)
    df = df[['Open', 'High', 'Low', 'Close', 'Volume']]
    df.dropna(inplace=True)
    return df

if __name__ == "__main__":
    df = fetch_data('AAPL', '2020-01-01', '2024-12-31')
    df.to_csv('data/AAPL.csv')
    print("Saved", len(df), "rows.")

