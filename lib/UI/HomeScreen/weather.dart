import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; // Add this for date/time formatting
import 'package:zrai_mart/UI/chatBot/SafetyMeasuresScreen.dart';

import '../../saller center/homeScreen/RecomandedProductsScreen.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? weatherData;
  String errorMessage = '';
  Position? _currentPosition;
  String cityName = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isSaller = false;


  @override
  void initState() {
    super.initState();
    _fetchUserData();
    fetchLocation();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('saller').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            isSaller = true;
          });
        } else {
          setState(() {
            isSaller = false;
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() {
          isSaller = false;
        });
      }
    }
  }

  Future<void> fetchLocation() async {
    final permissionStatus = await Permission.location.request();
    if (permissionStatus.isGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        cityName = await _getCityName(_currentPosition!.latitude, _currentPosition!.longitude);
        fetchWeatherData();
      } catch (e) {
        setState(() {
          errorMessage = 'Error fetching location: $e';
        });
      }
    } else {
      setState(() {
        errorMessage = 'Location permission not granted';
      });
    }
  }

  Future<String> _getCityName(double latitude, double longitude) async {
    final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['address']['city'] ?? 'Unknown City';
      } else {
        return 'Unknown City';
      }
    } catch (e) {
      return 'Unknown City';
    }
  }

  Future<void> fetchWeatherData() async {
    if (_currentPosition == null) return;

    final url =
        'https://api.open-meteo.com/v1/forecast?latitude=${_currentPosition!.latitude}&longitude=${_currentPosition!.longitude}&current=temperature_2m,wind_speed_10m&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation';


    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load weather data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // Get current hour and today's date
    final currentDate = DateTime.now();
    final currentHour = currentDate.hour;
    final formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather Forecast"),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: weatherData == null
          ? errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 10),
              SizedBox(
                width: 120,
                height: 80,
                child: Image.asset("assets/cloud.png"),
              ),
              Text(
                "${weatherData!['current']['temperature_2m']}°C",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                cityName,
                style: const TextStyle(color: Colors.green, fontSize: 16),
              ),
              Text(
                "Wind Speed: ${weatherData!['current']['wind_speed_10m']} m/s",
                style: const TextStyle(color: Colors.green),
              ),
              // Display Date and Time
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "Date: $formattedDate",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: width / 1.3,
                height: height / 4,
                child: Image.asset(
                  "assets/rainHome.png",
                  width: 200,
                  height: 200,
                ),
              ),
              Container(
                width: width / 1.3,
                height: height / 3.5,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Today",
                            style: TextStyle(color: Colors.white54),
                          ),
                          Text(
                            "${weatherData!['hourly']['time'][0].substring(0, 10)}",
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: width / 1.3,
                      height: 2,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Horizontal list view for weather data from current hour onward
                    SizedBox(
                      height: 150, // Adjust as per requirement
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: weatherData!['hourly']['time'].length, // Number of weather data items to display
                        itemBuilder: (context, index) {
                          final timeStr = weatherData!['hourly']['time'][index];
                          final hour = int.parse(timeStr.substring(11, 13));
                          final date = timeStr.substring(0, 10);

                          // If the date is today, only show hours that are equal to or greater than the current hour
                          if (date == formattedDate && hour < currentHour) {
                            return const SizedBox.shrink(); // Skip previous hours today
                          }

                          // Otherwise, display the data normally (show data for future days)
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Column(
                              children: [
                                Text(
                                  timeStr.substring(11, 16),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Image.asset(
                                  "assets/iconweather.png",
                                  width: 60,
                                  height: 60,
                                ),
                                Text(
                                  "${weatherData!['hourly']['temperature_2m'][index]}°C",
                                  style: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                ),
                                Text(
                                  "${weatherData!['hourly']['relative_humidity_2m'][index]}%",
                                  style: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                ),
                                Text(
                                  "${weatherData!['hourly']['wind_speed_10m'][index]} km/h ",
                                  style: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                   GestureDetector(
                    onTap: () {
                      /*Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CropReccommendation(p: p,ph: ph,k: k,n: n,temperature: weatherData!['current']['temperature_2m'],humidity: double.parse(weatherData!['hourly']['relative_humidity_2m'][1].toString()),rainfall: double.parse(weatherData!['hourly']['precipitation'][1].toString(),)),
                        ),
                      );*/
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecommandedProductsScreen(temperature: weatherData!['current']['temperature_2m'],humidity: double.parse(weatherData!['hourly']['relative_humidity_2m'][1].toString()),rainfall: double.parse(weatherData!['hourly']['precipitation'][1].toString(),), currentPosition: _currentPosition!,) ,  ),
                      );
                    },
                    child: Container(
                      width: 150,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Center(
                        child: Text(
                          "Product Recommendation",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                                 ),
                   GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SafetyMeasuresScreen(city: cityName, temperature: weatherData!['current']['temperature_2m'], windSpeed: weatherData!['current']['wind_speed_10m'], currentDate: formattedDate.toString(),),
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Center(
                        child: Text(
                          "precaution measures",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                                 ),
                 ],
               ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
