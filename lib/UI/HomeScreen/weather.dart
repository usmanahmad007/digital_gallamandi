import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zrai_mart/UI/HomeScreen/WeatherMoreDetail.dart';

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

  @override
  void initState() {
    super.initState();
    fetchLocation();
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
        'https://api.open-meteo.com/v1/forecast?latitude=${_currentPosition!.latitude}&longitude=${_currentPosition!.longitude}&current=temperature_2m,wind_speed_10m&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m';

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

    return Scaffold(
      appBar: AppBar(
        title: Text("Weather Forecast"),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: weatherData == null
          ? errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 10),
              Container(
                width: 120,
                height: 80,
                child: Image.asset("assets/cloud.png"),
              ),
              Text(
                "${weatherData!['current']['temperature_2m']}°C",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              SizedBox(height: 10),
              Text(
                cityName,
                style: TextStyle(color: Colors.green, fontSize: 16),
              ),
              Text(
                "Wind Speed: ${weatherData!['current']['wind_speed_10m']} m/s",
                style: TextStyle(color: Colors.green),
              ),
              Container(
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
                height: height / 4.5,
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
                          Text(
                            "Today",
                            style: TextStyle(color: Colors.white54),
                          ),
                          Text(
                            "${weatherData!['hourly']['time'][0].substring(0, 10)}",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 3),
                    Container(
                      width: width / 1.3,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Center(
                          child: Column(
                            children: [
                              Text(
                                "${weatherData!['hourly']['time'][index].substring(11, 16)}",
                                style: TextStyle(color: Colors.white54),
                              ),
                              Image.asset(
                                "assets/iconweather.png",
                                width: 60,
                                height: 60,
                              ),
                              Text(
                                "${weatherData!['hourly']['temperature_2m'][index]}°C",
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              /*Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>WeatherMoreDetail()));
                      },
                      child: Container(
                        width: 150,
                        height: 35,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            "More Details",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 150,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          "Get Recommendation",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}
