# ML Backend for Prescription Abuse Detection

This directory contains the Machine Learning component of the Prescription Abuse Detection System. It uses a Random Forest model trained on the Kaggle U.S. Opiate Prescriptions dataset to predict risk levels based on prescription patterns.

## Setup

1.  **Install Python 3.9+**
2.  **Create a Virtual Environment** (Recommended):
    ```bash
    python -m venv venv
    # Windows
    venv\Scripts\activate
    # Mac/Linux
    source venv/bin/activate
    ```
3.  **Install Dependencies**:
    ```bash
    pip install -r requirements.txt
    ```

## Training the Model

The model is trained on `dataset/kaggle/prescriber-info.csv`.

To train the model:
```bash
python train_model.py
```
This will:
- Load the dataset
- Preprocess features (normalize drug counts)
- Split data (70% Train, 20% Test, 10% Val)
- Train a Random Forest Classifier
- Save the model to `models/random_forest_model.pkl`

## Model Performance

The model was trained and evaluated with the following results:
- **Test Accuracy:** 94.00%
- **Validation Accuracy:** 93.32%
- **Model Type:** Random Forest Classifier (100 trees)

## Running the API

To start the Flask REST API:
```bash
python app.py
```
The server will start at `http://localhost:5000`.

## API Endpoints

### `POST /predict`
Predicts risk level for a list of prescriptions.

**Request Body:**
```json
{
  "prescriptions": [
    {"drugName": "OxyContin"},
    {"drugName": "Hydrocodone"},
    {"drugName": "Ibuprofen"}
  ]
}
```

**Response:**
```json
{
  "risk_level": "High",
  "risk_score": 85.5,
  "confidence": 92.0,
  "probabilities": {
    "High": 85.5,
    "Medium": 10.0,
    "Low": 4.5
  }
}
```
