from flask import Flask, request, jsonify
from flask_cors import CORS
from utils import fetch_and_predict

app = Flask(__name__)
CORS(app)  # Allow Flutter web/app to access this

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    ticker = data.get("ticker")
    start = data.get("start")
    end = data.get("end")
    features = data.get("features")  # Optional

    try:
        result = fetch_and_predict(ticker, start, end, features)
        return jsonify({"status": "success", "data": result})
    except Exception as e:
        import traceback
        traceback.print_exc()  # This will print the full error in your terminal
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True)
