from flask import Flask, request, jsonify
from flask_cors import CORS
from utils import fetch_and_predict, save_model, load_model, list_models, run_backtest, optimize_portfolio, get_stock_sentiment, delete_model
import os
import requests
from datetime import datetime, timedelta
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flasgger import Swagger

app = Flask(__name__)
CORS(app)  # Allow Flutter web/app to access this
swagger = Swagger(app)

# Add rate limiting: 30 requests per minute per IP
limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=["30 per minute"]
)

# Simple in-memory cache for daily updates
cache = {
    'gainers': {'data': None, 'timestamp': None},
    'losers': {'data': None, 'timestamp': None},
}

NODE_API_BASE = 'http://localhost:3000/nse'  # Example: replace with your deployed Node.js API

@app.route('/predict', methods=['POST'])
def predict():
    """
    Predict stock returns using the selected model and features.
    ---
    tags:
      - Prediction
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            ticker:
              type: string
              example: AAPL
            start:
              type: string
              example: 2024-01-01
            end:
              type: string
              example: 2024-12-31
            features:
              type: array
              items:
                type: string
            model_name:
              type: string
              example: latest_model.pkl
    responses:
      200:
        description: Prediction result
      500:
        description: Error
    """
    data = request.get_json()
    ticker = data.get("ticker")
    start = data.get("start")
    end = data.get("end")
    features = data.get("features")  # Optional
    model_name = data.get("model_name")  # Optional

    try:
        result = fetch_and_predict(ticker, start, end, features, model_name)
        return jsonify({"status": "success", "data": result})
    except Exception as e:
        import traceback
        traceback.print_exc()  # This will print the full error in your terminal
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/save_model', methods=['POST'])
def save_model_route():
    """
    Save the current model to disk.
    ---
    tags:
      - Model Management
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            model_name:
              type: string
              example: my_model.pkl
    responses:
      200:
        description: Model saved
      500:
        description: Error
    """
    data = request.get_json()
    model_name = data.get("model_name", "latest_model.pkl")
    try:
        save_model(model_name)
        return jsonify({"status": "success", "message": f"Model saved as {model_name}"})
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/load_model', methods=['POST'])
def load_model_route():
    """
    Load a model from disk.
    ---
    tags:
      - Model Management
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            model_name:
              type: string
              example: my_model.pkl
    responses:
      200:
        description: Model loaded
      500:
        description: Error
    """
    data = request.get_json()
    model_name = data.get("model_name", "latest_model.pkl")
    try:
        load_model(model_name)
        return jsonify({"status": "success", "message": f"Model {model_name} loaded"})
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/list_models', methods=['GET'])
def list_models_route():
    """
    List all saved models.
    ---
    tags:
      - Model Management
    responses:
      200:
        description: List of models
      500:
        description: Error
    """
    try:
        models = list_models()
        return jsonify({"status": "success", "models": models})
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/top_gainers', methods=['GET'])
def top_gainers():
    """
    Get top gainers from the stock market.
    ---
    tags:
      - Market Data
    responses:
      200:
        description: Top gainers
      500:
        description: Error
    """
    now = datetime.now()
    # Cache for 10 minutes
    if cache['gainers']['data'] and cache['gainers']['timestamp'] and (now - cache['gainers']['timestamp']) < timedelta(minutes=10):
        return jsonify({'status': 'success', 'data': cache['gainers']['data']})
    try:
        resp = requests.get(f'{NODE_API_BASE}/get_gainers', timeout=10)
        resp.raise_for_status()
        data = resp.json()
        cache['gainers'] = {'data': data, 'timestamp': now}
        return jsonify({'status': 'success', 'data': data})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/top_losers', methods=['GET'])
def top_losers():
    """
    Get top losers from the stock market.
    ---
    tags:
      - Market Data
    responses:
      200:
        description: Top losers
      500:
        description: Error
    """
    now = datetime.now()
    if cache['losers']['data'] and cache['losers']['timestamp'] and (now - cache['losers']['timestamp']) < timedelta(minutes=10):
        return jsonify({'status': 'success', 'data': cache['losers']['data']})
    try:
        resp = requests.get(f'{NODE_API_BASE}/get_losers', timeout=10)
        resp.raise_for_status()
        data = resp.json()
        cache['losers'] = {'data': data, 'timestamp': now}
        return jsonify({'status': 'success', 'data': data})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/backtest', methods=['POST'])
def backtest():
    """
    Run a backtest on the selected strategy and model.
    ---
    tags:
      - Backtest
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            ticker:
              type: string
              example: AAPL
            start:
              type: string
              example: 2024-01-01
            end:
              type: string
              example: 2024-12-31
            features:
              type: array
              items:
                type: string
            model_name:
              type: string
              example: latest_model.pkl
            threshold:
              type: number
              example: 0.0
            holding_period:
              type: integer
              example: 1
            allow_short:
              type: boolean
              example: false
    responses:
      200:
        description: Backtest result
      500:
        description: Error
    """
    data = request.get_json()
    ticker = data.get("ticker")
    start = data.get("start")
    end = data.get("end")
    features = data.get("features")  # Optional
    model_name = data.get("model_name")  # Optional
    threshold = data.get("threshold", 0.0)
    holding_period = data.get("holding_period", 1)
    allow_short = data.get("allow_short", False)
    try:
        result = run_backtest(ticker, start, end, features, model_name, threshold, holding_period, allow_short)
        return jsonify({"status": "success", "data": result})
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/optimize_portfolio', methods=['POST'])
def optimize_portfolio_route():
    """
    Optimize a portfolio for maximum Sharpe ratio.
    ---
    tags:
      - Portfolio
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            tickers:
              type: array
              items:
                type: string
            quantities:
              type: array
              items:
                type: number
            risk_free_rate:
              type: number
              example: 0.02
    responses:
      200:
        description: Portfolio optimization result
      400:
        description: User error
      500:
        description: Error
    """
    data = request.get_json()
    tickers = data.get('tickers')
    quantities = data.get('quantities')
    risk_free_rate = data.get('risk_free_rate', 0.02)
    try:
        result = optimize_portfolio(tickers, quantities, risk_free_rate)
        return jsonify({'status': 'success', 'data': result})
    except ValueError as e:
        # User-facing error (e.g., no asset exceeds risk-free rate)
        return jsonify({'status': 'error', 'message': str(e)}), 400
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/sentiment', methods=['POST'])
def sentiment_analysis():
    """
    Get sentiment analysis for a stock ticker.
    ---
    tags:
      - Sentiment
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            ticker:
              type: string
              example: AAPL
    responses:
      200:
        description: Sentiment analysis result
      400:
        description: Missing ticker
      500:
        description: Error
    """
    data = request.get_json()
    ticker = data.get('ticker')
    
    if not ticker:
        return jsonify({'status': 'error', 'message': 'Ticker is required'}), 400
    
    try:
        result = get_stock_sentiment(ticker.upper())
        return jsonify({'status': 'success', 'data': result})
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/delete_model', methods=['POST'])
def delete_model_route():
    """
    Delete a saved model by name.
    ---
    tags:
      - Model Management
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            model_name:
              type: string
              example: my_model.pkl
    responses:
      200:
        description: Model deleted
      400:
        description: Missing model name
      404:
        description: Model not found
      500:
        description: Error
    """
    data = request.get_json()
    model_name = data.get('model_name')
    if not model_name:
        return jsonify({'status': 'error', 'message': 'Model name required'}), 400
    try:
        deleted = delete_model(model_name)
        if deleted:
            return jsonify({'status': 'success', 'message': f'Model {model_name} deleted'})
        else:
            return jsonify({'status': 'error', 'message': f'Model {model_name} not found'}), 404
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'status': 'error', 'message': str(e)}), 500

# Error handler for rate limit exceeded
@app.errorhandler(429)
def ratelimit_handler(e):
    return jsonify({'status': 'error', 'message': 'Rate limit exceeded. Please try again later.'}), 429

if __name__ == "__main__":
    if not os.path.exists('models'):
        os.makedirs('models')
    app.run(host="0.0.0.0", port=5000, debug=True)
