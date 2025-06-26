import pandas as pd
import yfinance as yf
from sklearn.linear_model import LinearRegression
import pandas_ta as ta
import joblib
import os
import shap
import math
from pypfopt import EfficientFrontier, risk_models, expected_returns
import requests
from textblob import TextBlob
from datetime import datetime, timedelta
import json
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

MODEL_DIR = 'models'
LATEST_MODEL = os.path.join(MODEL_DIR, 'latest_model.pkl')

# NewsAPI configuration (you'll need to get a free API key from newsapi.org)
NEWS_API_KEY = os.getenv('NEWS_API_KEY', 'your_news_api_key_here')

# Save the model to disk
model_cache = {}

def analyze_sentiment(text):
    """Analyze sentiment of text using TextBlob"""
    try:
        blob = TextBlob(text)
        return {
            'polarity': blob.sentiment.polarity,  # -1 to 1 (negative to positive)
            'subjectivity': blob.sentiment.subjectivity,  # 0 to 1 (objective to subjective)
            'sentiment': 'positive' if blob.sentiment.polarity > 0.1 else 'negative' if blob.sentiment.polarity < -0.1 else 'neutral'
        }
    except Exception as e:
        return {
            'polarity': 0.0,
            'subjectivity': 0.0,
            'sentiment': 'neutral'
        }

def fetch_news_sentiment(ticker, days_back=7):
    """Fetch news articles and analyze sentiment for a given ticker"""
    try:
        # Get company name from yfinance for better news search
        stock = yf.Ticker(ticker)
        company_name = stock.info.get('longName', ticker)
        
        # Search for news articles
        url = f"https://newsapi.org/v2/everything"
        params = {
            'q': f'"{ticker}" OR "{company_name}"',
            'from': (datetime.now() - timedelta(days=days_back)).strftime('%Y-%m-%d'),
            'to': datetime.now().strftime('%Y-%m-%d'),
            'language': 'en',
            'sortBy': 'publishedAt',
            'apiKey': NEWS_API_KEY,
            'pageSize': 20
        }
        
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        if data.get('status') != 'ok':
            return {
                'error': 'News API error',
                'articles': [],
                'sentiment_summary': {'polarity': 0.0, 'subjectivity': 0.0, 'sentiment': 'neutral'}
            }
        
        articles = data.get('articles', [])
        if not articles:
            return {
                'error': 'No news articles found',
                'articles': [],
                'sentiment_summary': {'polarity': 0.0, 'subjectivity': 0.0, 'sentiment': 'neutral'}
            }
        
        # Analyze sentiment for each article
        sentiments = []
        processed_articles = []
        
        for article in articles:
            title = article.get('title', '')
            description = article.get('description', '')
            content = article.get('content', '')
            
            # Combine title and description for sentiment analysis
            text = f"{title}. {description}"
            sentiment = analyze_sentiment(text)
            
            processed_article = {
                'title': title,
                'description': description,
                'url': article.get('url', ''),
                'publishedAt': article.get('publishedAt', ''),
                'source': article.get('source', {}).get('name', ''),
                'sentiment': sentiment
            }
            
            processed_articles.append(processed_article)
            sentiments.append(sentiment['polarity'])
        
        # Calculate overall sentiment
        if sentiments:
            avg_polarity = sum(sentiments) / len(sentiments)
            overall_sentiment = 'positive' if avg_polarity > 0.1 else 'negative' if avg_polarity < -0.1 else 'neutral'
        else:
            avg_polarity = 0.0
            overall_sentiment = 'neutral'
        
        return {
            'articles': processed_articles,
            'sentiment_summary': {
                'polarity': round(avg_polarity, 3),
                'subjectivity': 0.5,  # Average subjectivity
                'sentiment': overall_sentiment,
                'article_count': len(processed_articles)
            }
        }
        
    except requests.exceptions.RequestException as e:
        return {
            'error': f'Network error: {str(e)}',
            'articles': [],
            'sentiment_summary': {'polarity': 0.0, 'subjectivity': 0.0, 'sentiment': 'neutral'}
        }
    except Exception as e:
        return {
            'error': f'Error fetching news: {str(e)}',
            'articles': [],
            'sentiment_summary': {'polarity': 0.0, 'subjectivity': 0.0, 'sentiment': 'neutral'}
        }

def get_stock_sentiment(ticker):
    """Get comprehensive sentiment analysis for a stock"""
    try:
        # Fetch news sentiment
        news_data = fetch_news_sentiment(ticker)
        
        # Get stock info for context
        stock = yf.Ticker(ticker)
        info = stock.info
        
        # Calculate sentiment score based on news and technical indicators
        sentiment_score = 0.0
        sentiment_factors = []
        
        # News sentiment factor (40% weight)
        if 'sentiment_summary' in news_data and 'polarity' in news_data['sentiment_summary']:
            news_polarity = news_data['sentiment_summary']['polarity']
            sentiment_score += news_polarity * 0.4
            sentiment_factors.append({
                'factor': 'News Sentiment',
                'value': news_polarity,
                'weight': 0.4,
                'description': f"News sentiment: {news_data['sentiment_summary']['sentiment']}"
            })
        
        # Price momentum factor (30% weight)
        try:
            hist = stock.history(period='30d')
            if not hist.empty:
                current_price = hist['Close'].iloc[-1]
                price_30d_ago = hist['Close'].iloc[0]
                price_momentum = (current_price - price_30d_ago) / price_30d_ago
                sentiment_score += min(max(price_momentum, -0.5), 0.5) * 0.3
                sentiment_factors.append({
                    'factor': 'Price Momentum',
                    'value': price_momentum,
                    'weight': 0.3,
                    'description': f"30-day price change: {price_momentum:.2%}"
                })
        except:
            pass
        
        # Volume factor (20% weight)
        try:
            if not hist.empty:
                avg_volume = hist['Volume'].mean()
                current_volume = hist['Volume'].iloc[-1]
                volume_ratio = current_volume / avg_volume if avg_volume > 0 else 1.0
                volume_factor = min(max((volume_ratio - 1) * 0.5, -0.5), 0.5)
                sentiment_score += volume_factor * 0.2
                sentiment_factors.append({
                    'factor': 'Volume',
                    'value': volume_factor,
                    'weight': 0.2,
                    'description': f"Volume ratio: {volume_ratio:.2f}x average"
                })
        except:
            pass
        
        # Market cap factor (10% weight)
        try:
            market_cap = info.get('marketCap', 0)
            if market_cap > 0:
                # Large caps tend to be more stable
                market_cap_factor = min(market_cap / 1e12, 1.0) * 0.1
                sentiment_score += market_cap_factor * 0.1
                sentiment_factors.append({
                    'factor': 'Market Cap',
                    'value': market_cap_factor,
                    'weight': 0.1,
                    'description': f"Market cap: ${market_cap/1e9:.1f}B"
                })
        except:
            pass
        
        # Determine overall sentiment
        if sentiment_score > 0.2:
            overall_sentiment = 'bullish'
        elif sentiment_score < -0.2:
            overall_sentiment = 'bearish'
        else:
            overall_sentiment = 'neutral'
        
        return {
            'ticker': ticker,
            'overall_sentiment': overall_sentiment,
            'sentiment_score': round(sentiment_score, 3),
            'sentiment_factors': sentiment_factors,
            'news_data': news_data,
            'stock_info': {
                'name': info.get('longName', ticker),
                'sector': info.get('sector', 'Unknown'),
                'industry': info.get('industry', 'Unknown'),
                'market_cap': info.get('marketCap', 0),
                'current_price': info.get('currentPrice', 0)
            }
        }
        
    except Exception as e:
        return {
            'ticker': ticker,
            'error': f'Error analyzing sentiment: {str(e)}',
            'overall_sentiment': 'neutral',
            'sentiment_score': 0.0,
            'sentiment_factors': [],
            'news_data': {'articles': [], 'sentiment_summary': {'polarity': 0.0, 'subjectivity': 0.0, 'sentiment': 'neutral'}},
            'stock_info': {}
        }

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

def safe_stat(val):
    if val is None or isinstance(val, str):
        return 0.0
    if isinstance(val, float) and (math.isnan(val) or math.isinf(val)):
        return 0.0
    return float(val)

def run_backtest(ticker, start, end, features=None, model_name=None, threshold=0.0, holding_period=1, allow_short=False):
    start = start[:10]
    end = end[:10]
    df = yf.download(ticker, start=start, end=end)
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

    if df.empty:
        raise ValueError('No data available for this ticker and date range. Try a different range or ticker.')

    all_features = [
        'Return_Lag_1', 'Return_Lag_5', 'MA_10', 'RSI_14',
        'BBL_20', 'BBM_20', 'BBU_20',
        'MACD', 'MACD_signal', 'MACD_hist',
        'STOCH_k', 'STOCH_d', 'ATR_14'
    ]
    if features is None:
        features = all_features
    else:
        features = [f for f in features if f in all_features]
        if not features:
            features = all_features

    X = df[features]
    y = df['Return']

    global model_cache
    if model_name:
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

    if model_name:
        save_model(model_name)

    df['Predicted_Return'] = model.predict(X)
    n = len(df)
    signals = [0] * n
    strat_returns = [0.0] * n
    i = 0
    while i < n:
        pred = df['Predicted_Return'].iloc[i]
        if pred > threshold:
            # Buy and hold for holding_period days
            for j in range(i, min(i + holding_period, n)):
                signals[j] = 1
                strat_returns[j] = df['Return'].iloc[j]
            i += holding_period
        elif allow_short and pred < -threshold:
            # Short and hold for holding_period days
            for j in range(i, min(i + holding_period, n)):
                signals[j] = -1
                strat_returns[j] = -df['Return'].iloc[j]
            i += holding_period
        else:
            i += 1
    df['Signal'] = signals
    df['Strategy_Return'] = strat_returns
    df['Cumulative_Market'] = (1 + df['Return']).cumprod()
    df['Cumulative_Strategy'] = (1 + df['Strategy_Return']).cumprod()

    # Trade stats
    trades = sum(1 for s in signals if s != 0)
    win_trades = sum(1 for s, r in zip(signals, strat_returns) if s != 0 and r > 0)
    total_trades = sum(1 for s in signals if s != 0)
    win_rate = win_trades / total_trades if total_trades > 0 else 0
    max_drawdown = (df['Cumulative_Strategy'].cummax() - df['Cumulative_Strategy']).max()

    sharpe = df['Strategy_Return'].mean() / df['Strategy_Return'].std()
    trades = int(trades)
    win_rate = win_trades / total_trades if total_trades > 0 else 0
    max_drawdown = (df['Cumulative_Strategy'].cummax() - df['Cumulative_Strategy']).max()

    summary = {
        'market_return': df['Cumulative_Market'].iloc[-1] * 100 - 100,
        'strategy_return': df['Cumulative_Strategy'].iloc[-1] * 100 - 100,
        'sharpe': sharpe,
        'trades': trades,
        'win_rate': win_rate * 100,
        'max_drawdown': max_drawdown * 100
    }
    # Sanitize and round all float stats except trades
    for k in summary:
        if k != 'trades':
            summary[k] = round(safe_stat(summary[k]), 2)
    return {
        'dates': df.index.strftime('%Y-%m-%d').tolist(),
        'signals': df['Signal'].tolist(),
        'predicted_returns': df['Predicted_Return'].round(4).tolist(),
        'actual_returns': df['Return'].round(4).tolist(),
        'strategy_returns': df['Strategy_Return'].round(4).tolist(),
        'cumulative_market': df['Cumulative_Market'].round(4).tolist(),
        'cumulative_strategy': df['Cumulative_Strategy'].round(4).tolist(),
        'summary': summary,
        'features_used': features,
        'threshold': threshold,
        'holding_period': holding_period,
        'allow_short': allow_short
    }

def optimize_portfolio(tickers, quantities, risk_free_rate=0.02):
    import yfinance as yf
    import numpy as np
    import pandas as pd
    if not tickers or not quantities or len(tickers) != len(quantities):
        raise ValueError('Tickers and quantities must be provided and have the same length.')
    # Download historical price data
    prices = yf.download(tickers, period='1y')
    if prices.empty:
        raise ValueError('No price data found for the given tickers and period.')
    dropped = []
    adj_close_frames = []
    if isinstance(prices.columns, pd.MultiIndex):
        # Robustly handle both MultiIndex orders
        for t in tickers:
            found = False
            for price_type in ['Adj Close', 'Close']:
                try:
                    # Try ('Adj Close', 'IBM')
                    s = prices[(price_type, t)]
                    adj_close_frames.append(s.rename(t))
                    found = True
                    break
                except KeyError:
                    try:
                        # Try ('IBM', 'Adj Close')
                        s = prices[(t, price_type)]
                        adj_close_frames.append(s.rename(t))
                        found = True
                        break
                    except KeyError:
                        continue
            if not found:
                dropped.append(t)
        if not adj_close_frames:
            raise ValueError("No valid tickers with 'Adj Close' or 'Close' found in downloaded data.")
        prices = pd.concat(adj_close_frames, axis=1)
    else:
        # Single ticker: try both 'Adj Close' and 'Close'
        col = None
        if 'Adj Close' in prices.columns:
            col = 'Adj Close'
        elif 'Close' in prices.columns:
            col = 'Close'
        if col is None:
            raise ValueError("'Adj Close' or 'Close' not found in downloaded data.")
        adj_close = prices[col]
        if isinstance(adj_close, pd.Series):
            adj_close = adj_close.to_frame(name=tickers[0])
        prices = adj_close
    mu = expected_returns.mean_historical_return(prices)
    S = risk_models.sample_cov(prices)
    ef = EfficientFrontier(mu, S)
    try:
        weights = ef.max_sharpe(risk_free_rate=risk_free_rate)
    except ValueError as e:
        raise ValueError("No asset in your portfolio has an expected return exceeding the risk-free rate. Try lowering the risk-free rate or using different tickers.") from e
    cleaned_weights = ef.clean_weights()
    perf = ef.portfolio_performance(verbose=False, risk_free_rate=risk_free_rate)
    result = {
        'optimal_weights': cleaned_weights,
        'expected_return': perf[0],
        'expected_volatility': perf[1],
        'sharpe_ratio': perf[2],
    }
    if dropped:
        result['warning'] = f"The following tickers were excluded due to missing data: {', '.join(dropped)}"
    return result
