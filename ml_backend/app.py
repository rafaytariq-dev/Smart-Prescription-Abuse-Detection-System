from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import pandas as pd
import numpy as np
import os

app = Flask(__name__)
CORS(app)

# Load Model and Features
MODEL_PATH = 'models/random_forest_model.pkl'
FEATURES_PATH = 'models/feature_names.pkl'

model = None
feature_names = None

def load_artifacts():
    global model, feature_names
    try:
        if os.path.exists(MODEL_PATH) and os.path.exists(FEATURES_PATH):
            model = joblib.load(MODEL_PATH)
            feature_names = joblib.load(FEATURES_PATH)
            print("Model and features loaded successfully.")
        else:
            print("Model files not found. Please run train_model.py first.")
    except Exception as e:
        print(f"Error loading model: {e}")

load_artifacts()

@app.route('/health', methods=['GET'])
def health_check():
    status = "active" if model is not None else "inactive"
    return jsonify({"status": status, "model_loaded": model is not None})

@app.route('/predict', methods=['POST'])
def predict():
    if not model:
        return jsonify({"error": "Model not loaded"}), 503
        
    try:
        data = request.get_json()
        prescriptions = data.get('prescriptions', [])
        
        if not prescriptions:
            return jsonify({
                "risk_level": "Low",
                "risk_score": 0.0,
                "message": "No prescriptions provided"
            })

        # Convert input list of drug names to a dataframe row matching training features
        # 1. Count occurrences of each drug in the input
        input_counts = {}
        total_prescriptions = len(prescriptions)
        
        for p in prescriptions:
            drug_name = p.get('drugName', '').upper().replace(' ', '.').replace('-', '.')
            # Try to match with feature names (simple matching)
            # In a real app, you'd want fuzzy matching or a standardized drug dictionary
            matched = False
            for feature in feature_names:
                if drug_name in feature or feature in drug_name:
                    input_counts[feature] = input_counts.get(feature, 0) + 1
                    matched = True
                    break
            
        # 2. Create a feature vector
        features = pd.DataFrame(0, index=[0], columns=feature_names)
        
        for drug, count in input_counts.items():
            if drug in features.columns:
                features.at[0, drug] = count / total_prescriptions # Normalize to share
                
        # 3. Predict
        prediction = model.predict(features)[0]
        probabilities = model.predict_proba(features)[0]
        
        # Map class index to label (assuming classes are sorted alphabetically: High, Low, Medium)
        # We need to know the class order from the model
        class_labels = model.classes_
        risk_score = 0.0
        
        # Calculate a continuous risk score (0-100)
        # If High is predicted, score is 70-100 based on prob
        # If Medium, 30-70
        # If Low, 0-30
        
        high_idx = np.where(class_labels == 'High')[0]
        med_idx = np.where(class_labels == 'Medium')[0]
        low_idx = np.where(class_labels == 'Low')[0]
        
        prob_high = probabilities[high_idx][0] if len(high_idx) > 0 else 0
        prob_med = probabilities[med_idx][0] if len(med_idx) > 0 else 0
        
        # Weighted score
        # High * 100 + Medium * 50 + Low * 0
        raw_score = (prob_high * 100) + (prob_med * 50)
        
        return jsonify({
            "risk_level": prediction,
            "risk_score": round(raw_score, 1),
            "confidence": round(max(probabilities) * 100, 1),
            "probabilities": {
                label: round(prob * 100, 1) 
                for label, prob in zip(class_labels, probabilities)
            }
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

from trie import Trie

# Initialize Trie
patient_trie = Trie()

@app.route('/sync_patients', methods=['POST'])
def sync_patients():
    try:
        data = request.get_json()
        patients = data.get('patients', [])
        
        patient_trie.clear()
        
        for p in patients:
            # Index by Name parts
            name_parts = p.get('name', '').split(' ')
            for part in name_parts:
                patient_trie.insert(part, p)
            
            # Index by Full Name
            patient_trie.insert(p.get('name', ''), p)
            
            # Index by ID
            patient_trie.insert(p.get('id', ''), p)
            
            # Index by Phone
            patient_trie.insert(p.get('phone', ''), p)
            
        return jsonify({"message": f"Synced {len(patients)} patients"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/search_patients', methods=['GET'])
def search_patients():
    try:
        query = request.args.get('query', '')
        if not query:
            return jsonify([])
            
        results = patient_trie.search(query)
        
        # Deduplicate results based on ID
        seen_ids = set()
        unique_results = []
        for p in results:
            if p['id'] not in seen_ids:
                unique_results.append(p)
                seen_ids.add(p['id'])
                
        return jsonify(unique_results), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
