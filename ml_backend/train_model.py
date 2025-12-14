import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import joblib
import os

# Configuration
DATASET_PATH = '../dataset/kaggle/prescriber-info.csv'
OPIOIDS_PATH = '../dataset/kaggle/opioids.csv'
MODEL_DIR = 'models'
RANDOM_SEED = 42

def load_data():
    print("Loading dataset...")
    if not os.path.exists(DATASET_PATH):
        raise FileNotFoundError(f"Dataset not found at {DATASET_PATH}")
    
    df = pd.read_csv(DATASET_PATH)
    opioids_df = pd.read_csv(OPIOIDS_PATH)
    
    # Clean column names in opioids dataset to match prescriber dataset
    # The prescriber dataset uses dots instead of spaces/hyphens (e.g., "HYDROCODONE.ACETAMINOPHEN")
    opioid_names = opioids_df['Drug Name'].unique()
    formatted_opioid_names = [name.replace(' ', '.').replace('-', '.') for name in opioid_names]
    
    return df, formatted_opioid_names

def preprocess_data(df, opioid_names):
    print("Preprocessing data...")
    
    # 1. Identify drug columns (columns that are not metadata)
    metadata_cols = ['NPI', 'Gender', 'State', 'Credentials', 'Specialty', 'Opioid.Prescriber']
    drug_cols = [col for col in df.columns if col not in metadata_cols]
    
    # 2. Calculate total prescriptions per prescriber
    df['Total_Prescriptions'] = df[drug_cols].sum(axis=1)
    
    # Filter out prescribers with very few prescriptions to avoid noise
    df = df[df['Total_Prescriptions'] > 10].copy()
    
    # 3. Identify opioid columns present in the dataset
    # Find intersection of known opioids and dataset columns
    present_opioid_cols = [col for col in drug_cols if any(op in col for op in opioid_names)]
    
    # 4. Calculate Opioid Rate (Target Variable Logic)
    df['Opioid_Count'] = df[present_opioid_cols].sum(axis=1)
    df['Opioid_Rate'] = df['Opioid_Count'] / df['Total_Prescriptions']
    
    # 5. Define Risk Labels (Synthetic Target)
    # High Risk: > 40% opioids
    # Medium Risk: 10-40% opioids
    # Low Risk: < 10% opioids
    conditions = [
        (df['Opioid_Rate'] >= 0.4),
        (df['Opioid_Rate'] >= 0.1) & (df['Opioid_Rate'] < 0.4)
    ]
    choices = ['High', 'Medium']
    df['Risk_Level'] = np.select(conditions, choices, default='Low')
    
    print(f"Risk Level Distribution:\n{df['Risk_Level'].value_counts()}")
    
    # 6. Feature Engineering: Normalize drug counts to shares
    # This is crucial so the model works for a patient with 5 drugs vs a doctor with 5000
    X = df[drug_cols].div(df['Total_Prescriptions'], axis=0).fillna(0)
    y = df['Risk_Level']
    
    return X, y, drug_cols

def train_model():
    # Create models directory
    if not os.path.exists(MODEL_DIR):
        os.makedirs(MODEL_DIR)
        
    # Load and Process
    df, opioid_names = load_data()
    X, y, feature_names = preprocess_data(df, opioid_names)
    
    # Split Data: 70% Train, 20% Test, 10% Validation
    # First split: 70% Train, 30% Temp (Test + Val)
    X_train, X_temp, y_train, y_temp = train_test_split(
        X, y, test_size=0.3, random_state=RANDOM_SEED, stratify=y
    )
    
    # Second split: Split Temp into 20% Test (2/3 of 30%) and 10% Val (1/3 of 30%)
    X_test, X_val, y_test, y_val = train_test_split(
        X_temp, y_temp, test_size=1/3, random_state=RANDOM_SEED, stratify=y_temp
    )
    
    print(f"\nData Splits:")
    print(f"Training: {X_train.shape[0]} samples ({X_train.shape[0]/len(X):.1%})")
    print(f"Testing:  {X_test.shape[0]} samples ({X_test.shape[0]/len(X):.1%})")
    print(f"Validation: {X_val.shape[0]} samples ({X_val.shape[0]/len(X):.1%})")
    
    # Train Random Forest
    print("\nTraining Random Forest Model...")
    rf_model = RandomForestClassifier(
        n_estimators=100,
        max_depth=15,
        random_state=RANDOM_SEED,
        n_jobs=-1
    )
    rf_model.fit(X_train, y_train)
    
    # Evaluate on Test Set
    print("\nEvaluating on Test Set...")
    y_pred = rf_model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    print(f"Test Accuracy: {accuracy:.4f}")
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred))
    
    # Validation Set Check
    print("\nValidation Set Check:")
    val_score = rf_model.score(X_val, y_val)
    print(f"Validation Accuracy: {val_score:.4f}")
    
    # Save Artifacts
    print("\nSaving model and artifacts...")
    joblib.dump(rf_model, os.path.join(MODEL_DIR, 'random_forest_model.pkl'))
    joblib.dump(feature_names, os.path.join(MODEL_DIR, 'feature_names.pkl'))
    
    print("Training complete!")

if __name__ == '__main__':
    train_model()
