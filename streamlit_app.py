import streamlit as st
import pandas as pd
import yfinance as yf
from sklearn.linear_model import LinearRegression
import matplotlib.pyplot as plt

st.set_page_config(page_title="Stock Return Estimator", layout="wide")

st.title("📈 Stock Return Estimator")

# --- Sidebar Inputs ---
st.sidebar.header("Stock Settings")
ticker = st.sidebar.text_input("Enter Stock Ticker", value="AAPL")
start_date = st.sidebar.date_input("Start Date", value=pd.to_datetime("2022-01-01"))
end_date = st.sidebar.date_input("End Date", value=pd.to_datetime("2024-01-01"))

if st.sidebar.button("Fetch and Predict"):
    with st.spinner("Fetching data..."):
        df = yf.download(ticker, start=start_date, end=end_date)
        df['Return'] = df['Close'].pct_change().shift(-1)
        df['Return_Lag_1'] = df['Close'].pct_change(1)
        df['Return_Lag_5'] = df['Close'].pct_change(5)
        df['MA_10'] = df['Close'].rolling(10).mean()
        df.dropna(inplace=True)

        # --- Model Training ---
        X = df[['Return_Lag_1', 'Return_Lag_5', 'MA_10']]
        y = df['Return']
        model = LinearRegression().fit(X, y)
        df['Predicted_Return'] = model.predict(X)

        # --- Strategy Simulation ---
        df['Strategy_Return'] = df['Predicted_Return'].apply(lambda x: 1 if x > 0 else 0) * df['Return']
        df['Cumulative_Market'] = (1 + df['Return']).cumprod()
        df['Cumulative_Strategy'] = (1 + df['Strategy_Return']).cumprod()

        # --- Results ---
        st.success("Prediction complete!")

        st.subheader("📊 Cumulative Returns")
        fig, ax = plt.subplots()
        ax.plot(df.index, df['Cumulative_Market'], label='Buy & Hold')
        ax.plot(df.index, df['Cumulative_Strategy'], label='Model Strategy')
        ax.legend()
        ax.set_title(f"{ticker} Strategy vs Market")
        st.pyplot(fig)

        st.subheader("📈 Recent Predictions")
        st.dataframe(df[['Close', 'Predicted_Return', 'Return']].tail(10).style.format("{:.4f}"))
