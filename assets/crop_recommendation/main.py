from fastapi import FastAPI
import pickle
import numpy as np

app = FastAPI()

# Load the saved components
model = pickle.load(open('model.pkl', 'rb'))
mx = pickle.load(open('minmaxscaler.pkl', 'rb'))
sc = pickle.load(open('standscaler.pkl', 'rb'))

@app.get("/predict")
def predict(n: float, p: float, k: float, temp: float, hum: float, ph: float, rain: float):
    # Create feature array
    features = np.array([[n, p, k, temp, hum, ph, rain]])

    # Apply the same transformations used in training
    transformed = sc.transform(mx.transform(features))

    # Predict
    prediction = model.predict(transformed)

    return {"crop": prediction[0]}