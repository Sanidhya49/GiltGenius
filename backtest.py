import pandas as pd
from sklearn.linear_model import LinearRegression

# Load data & features (same as training)
df = pd.read_csv('data/AAPL_features.csv', index_col=0, parse_dates=True)
X = df.drop(columns=['Return'])
y = df['Return']

# Train on full dataset
model = LinearRegression().fit(X, y)
df['Pred'] = model.predict(X)

# Strategy: If Pred > 0, go long; else, stay out
df['Strategy_Return'] = df['Pred'].apply(lambda p: 1 if p > 0 else 0) * df['Return']
df['Cumulative_Strategy'] = (1 + df['Strategy_Return']).cumprod()
df['Cumulative_Market'] = (1 + df['Return']).cumprod()

# Plot
import matplotlib.pyplot as plt
plt.figure()
plt.plot(df.index, df['Cumulative_Market'], label='Buy & Hold')
plt.plot(df.index, df['Cumulative_Strategy'], label='Strategy')
plt.legend()
plt.title('Backtest Performance')
plt.show()




