import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WeatherService {
  static const String _geoApiUrl = 'https://nominatim.openstreetmap.org/reverse';
  static const String _weatherApiUrl = 'https://api.open-meteo.com/v1/forecast';

  // 1. Check if user is a Seller
  static Future<bool> checkIfSeller() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('saller').doc(user.uid).get();
      return userDoc.exists;
    }
    return false;
  }

  // 2. Get Device Location
  static Future<Position> determinePosition() async {
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // 3. Get City Name from Lat/Long
  static Future<String> getCityName(double lat, double lon) async {
    final url = '$_geoApiUrl?format=json&lat=$lat&lon=$lon';
    final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'DigitalGallaMandi/1.0.0'});
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final address = data['address'];
      return address['city'] ?? address['town'] ?? address['village'] ?? 'Unknown Location';
    }
    return 'Unknown City';
  }

  // 4. Fetch Weather Data from API
  static Future<Map<String, dynamic>> fetchWeatherData(double lat, double lon) async {
    final url = '$_weatherApiUrl?latitude=$lat&longitude=$lon&current=temperature_2m,wind_speed_10m,weather_code&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation,weather_code';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather');
    }
  }

  // 5. Helper: Map Weather Codes to Icons
  static Map<String, dynamic> getWeatherDetails(int? code) {
    if (code == null) return {'icon': Icons.help_outline, 'label': 'Unknown'};
    if (code == 0) return {'icon': Icons.wb_sunny, 'label': 'Clear Sky'};
    if (code >= 1 && code <= 3) return {'icon': Icons.wb_cloudy, 'label': 'Partly Cloudy'};
    if (code >= 45 && code <= 48) return {'icon': Icons.blur_on, 'label': 'Foggy'};
    if (code >= 51 && code <= 67) return {'icon': Icons.umbrella, 'label': 'Rainy'};
    if (code >= 71 && code <= 77) return {'icon': Icons.ac_unit, 'label': 'Snowy'};
    if (code >= 80 && code <= 99) return {'icon': Icons.thunderstorm, 'label': 'Thunderstorm'};
    return {'icon': Icons.cloud, 'label': 'Cloudy'};
  }
}