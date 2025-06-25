from flask import Flask, request, jsonify
from flask_cors import CORS
from utils import fetch_and_predict, save_model, load_model, list_models
import os

app = Flask(__name__)
CORS(app)  # Allow Flutter web/app to access this

@app.route('/predict', methods=['POST'])
def predict():
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
    try:
        models = list_models()
        return jsonify({"status": "success", "models": models})
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == "__main__":
    if not os.path.exists('models'):
        os.makedirs('models')
    app.run(debug=True)
