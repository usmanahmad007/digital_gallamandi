import pickle
import numpy as np
import requests
import sys
import json

# Mapping labels to integer values
crop_dict = {
    'rice': 1, 'maize': 2, 'jute': 3, 'cotton': 4, 'coconut': 5, 'papaya': 6,
    'orange': 7, 'apple': 8, 'muskmelon': 9, 'watermelon': 10, 'grapes': 11,
    'mango': 12, 'banana': 13, 'pomegranate': 14, 'lentil': 15, 'blackgram': 16,
    'mungbean': 17, 'mothbeans': 18, 'pigeonpeas': 19, 'kidneybeans': 20,
    'chickpea': 21, 'coffee': 22 , 'wheat': 23, 'jowar': 24, 'dates': 25, 'garlic': 26, 'pear': 27,
    'soybean': 28, 'sorghum': 29, 'bajra': 30, 'bitter gourd': 31, 'barley': 32, 'tobacco': 33, 'tomato': 34,
    'pulses': 35, 'oilseeds': 36, 'gram': 37
}

# Load the model and scalers
randclf = pickle.load(open('model.pkl', 'rb'))
mx = pickle.load(open('minmaxscaler.pkl', 'rb'))
sc = pickle.load(open('standscaler.pkl', 'rb'))

API_KEY = '99cdc6713003303073302cf629d7f85a'

# Fetch weather data from OpenWeatherMap
def fetch_weather_data(city):
    url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={API_KEY}&units=metric"
    response = requests.get(url)
    data = response.json()
    if data["cod"] != 200:
        return None, None
    return data['main']['temp'], data['main']['humidity']

# Recommendation function
def recommendation(temperature, humidity):
    features = np.array([[temperature, humidity]])
    mx_features = mx.transform(features)
    sc_mx_features = sc.transform(mx_features)
    predicted_crop = randclf.predict(sc_mx_features).reshape(1, -1)
    predicted_crop_value = predicted_crop[0][0]
    crop_name = list(crop_dict.keys())[list(crop_dict.values()).index(predicted_crop_value)]
    return crop_name

if __name__ == "__main__":
    city = sys.argv[1]
    temperature, humidity = fetch_weather_data(city)
    if temperature and humidity:
        crop_name = recommendation(temperature, humidity)
        result = json.dumps({'crop_name': crop_name, 'temperature': temperature, 'humidity': humidity})
        print(result)
    else:
        print(json.dumps({'error': 'Unable to fetch weather data'}))
