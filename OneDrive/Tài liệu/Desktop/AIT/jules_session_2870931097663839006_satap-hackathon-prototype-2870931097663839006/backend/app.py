from flask import Flask, request, jsonify
from flask_cors import CORS
from ai_engine import assess_threat
from ledger import Blockchain
import logging

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Initialize Blockchain
satap_ledger = Blockchain()

# Configure logging
logging.basicConfig(level=logging.INFO)

@app.route('/api/assess_threat', methods=['POST'])
def api_assess_threat():
    data = request.json
    text = data.get('text', '')
    if not text:
        return jsonify({"error": "No text provided"}), 400
    
    result = assess_threat(text)
    return jsonify(result)

@app.route('/api/log_decision', methods=['POST'])
def api_log_decision():
    data = request.json
    # data expects: { "report_id": "...", "text": "...", "ai_score": 0.8, "analyst_action": "Escalate", "analyst_id": "..." }
    
    if not data:
        return jsonify({"error": "No data provided"}), 400

    block = satap_ledger.create_block(data)
    
    return jsonify({
        "message": "Decision logged successfully",
        "block": {
            "index": block.index,
            "hash": block.hash,
            "timestamp": block.timestamp
        }
    })

@app.route('/api/chain_status', methods=['GET'])
def api_chain_status():
    chain_data = satap_ledger.get_chain()
    is_valid = satap_ledger.verify_chain_integrity()
    
    return jsonify({
        "chain": chain_data,
        "is_valid": is_valid,
        "total_blocks": len(chain_data)
    })

if __name__ == '__main__':
    print("Starting SATAP Backend...")
    app.run(debug=True, port=5000)
