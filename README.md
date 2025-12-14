# Smart Prescription Abuse Detection System

An AI-powered platform that analyzes patient prescriptions to identify patterns of misuse, overuse, and doctor-shopping. This project is divided into a Flutter frontend (mobile app) and a Python Flask backend (ML model & API).

## Project Structure

- `frontend/`: Flutter codebase for the mobile application.
- `ml_backend/`: Python source code for the Machine Learning model and Flask API.
- `dataset/`: Training data (Included for model re-training).

## Prerequisites

- **Git**: [Install Git](https://git-scm.com/downloads)
- **Flutter SDK**: [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Python 3.9+**: [Install Python](https://www.python.org/downloads/)

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/rafaytariq-dev/Smart-Prescription-Abuse-Detection-System.git
cd Smart-Prescription-Abuse-Detection-System
```

### 2. Backend Setup (ML API)

The backend must be running for the frontend to receive risk analysis.

1.  Navigate to the backend directory:
    ```bash
    cd ml_backend
    ```

2.  Create and activate a virtual environment:
    ```bash
    # Windows
    python -m venv venv
    venv\Scripts\activate

    # Mac/Linux
    python3 -m venv venv
    source venv/bin/activate
    ```

3.  Install dependencies:
    ```bash
    pip install -r requirements.txt
    ```

4.  Run the server:
    ```bash
    python app.py
    ```
    The API will start at `http://localhost:5000`.

    > **Training**: To re-train the model using the included dataset, run:`python train_model.py`.

### 3. Frontend Setup (Flutter App)

1.  Navigate to the frontend directory:
    ```bash
    cd frontend
    ```

2.  Install dependencies:
    ```bash
    flutter pub get
    ```

3.  Run the app:
    ```bash
    flutter run
    ```

## Features

- **Risk Analysis**: ML model predicts risk levels (High, Medium, Low) based on prescription history.
- **Patient Search**: Fast trie-based search for patient records.
- **Dashboard**: Visual analytics for doctors and pharmacists.
