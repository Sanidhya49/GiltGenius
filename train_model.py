import pandas as pd
from sklearn.linear_model import LinearRegression, Ridge, Lasso
from sklearn.model_selection import TimeSeriesSplit
from sklearn.metrics import mean_absolute_error, mean_squared_error
import numpy as np

# 1. Load data
df = pd.read_csv('data/AAPL_features.csv', index_col=0, parse_dates=True)
X = df.drop(columns=['Return'])
y = df['Return']

# 2. Split with time-series cross-validation
tscv = TimeSeriesSplit(n_splits=5)
models = {
    'OLS': LinearRegression(),
    'Ridge': Ridge(alpha=1.0),
    'Lasso': Lasso(alpha=0.01)
}

results = {}
for name, model in models.items():
    mae_scores, rmse_scores = [], []
    for train_idx, test_idx in tscv.split(X):
        X_train, X_test = X.iloc[train_idx], X.iloc[test_idx]
        y_train, y_test = y.iloc[train_idx], y.iloc[test_idx]
        model.fit(X_train, y_train)
        preds = model.predict(X_test)
        mae_scores.append(mean_absolute_error(y_test, preds))
        rmse_scores.append(np.sqrt(mean_squared_error(y_test, preds)))
    results[name] = {
        'MAE': np.mean(mae_scores),
        'RMSE': np.mean(rmse_scores)
    }

print(pd.DataFrame(results).T)

