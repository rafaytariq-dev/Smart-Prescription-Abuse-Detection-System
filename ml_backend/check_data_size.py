import pandas as pd
try:
    df = pd.read_csv('../dataset/kaggle/prescriber-info.csv')
    print(f"Total Rows: {df.shape[0]}")
    print(f"Total Columns: {df.shape[1]}")
    
    # Check filtering logic from train_model.py
    metadata_cols = ['NPI', 'Gender', 'State', 'Credentials', 'Specialty', 'Opioid.Prescriber']
    drug_cols = [col for col in df.columns if col not in metadata_cols]
    df['Total_Prescriptions'] = df[drug_cols].sum(axis=1)
    df_filtered = df[df['Total_Prescriptions'] > 10]
    print(f"Filtered Rows (used for training): {df_filtered.shape[0]}")
except Exception as e:
    print(f"Error: {e}")
