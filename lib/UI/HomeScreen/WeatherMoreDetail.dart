import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherMoreDetail extends StatefulWidget {
  const WeatherMoreDetail({super.key});

  @override
  State<WeatherMoreDetail> createState() => _WeatherMoreDetailState();
}

class _WeatherMoreDetailState extends State<WeatherMoreDetail> {
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? weatherData;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    final latitude = 37.7749; // Example latitude
    final longitude = -122.4194; // Example longitude

    final url = 'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&daily=temperature_2m_max,temperature_2m_min&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m';

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

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 100,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 100,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

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
        child: Column(
          children: [
            SizedBox(height: 50),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "City Name", // Replace with actual city name
                    style: TextStyle(color: Colors.green, fontSize: 16),
                  ),
                  Text(
                    "Max: ${weatherData!['daily']['temperature_2m_max'][0]}°C Min: ${weatherData!['daily']['temperature_2m_min'][0]}°C",
                    style: TextStyle(color: Colors.green, fontSize: 16),
                  ),
                ],
              ),
            ),
            SizedBox(height: 50),
            Row(
              children: [
                SizedBox(width: 50),
                Text(
                  "7-Days Forecast",
                  style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 20),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios),
                        onPressed: _scrollLeft,
                      ),
                      SizedBox(
                        height: 150,
                        width: 250,
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: weatherData!['hourly']['temperature_2m'].length,
                          itemBuilder: (context, index) {
                            final time = weatherData!['hourly']['time'][index];
                            final temperature = weatherData!['hourly']['temperature_2m'][index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Container(
                                width: 70,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${temperature}°C",
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                    Image.asset(
                                      "assets/iconweather.png", // Replace with your icon asset
                                      width: 60,
                                      height: 60,
                                    ),
                                    Text(
                                      time.substring(11, 16),
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios),
                        onPressed: _scrollRight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Container(
                width: width / 1.5,
                height: 130,
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_searching,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(width: 5),
                          Text(
                            "AIR QUALITY",
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            "3-LOW HEALTH RISK",
                            style: TextStyle(
                                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        width: width / 1.5,
                        height: 4,
                        color: Colors.white,
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "See more",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 30,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: EdgeInsets.all(10),
                  width: 120,
                  height: 100,
                  decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sunny,
                              color: Colors.yellow,
                            ),
                            Text(
                              "SUNRISE",
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "5:38AM", // Replace with actual sunrise time
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Sunset: 7:25PM", // Replace with actual sunset time
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(10),
                  width: 120,
                  height: 100,
                  decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.water_drop,
                              color: Colors.blue,
                            ),
                            Text(
                              "UV INDEX",
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "4.7", // Replace with actual UV index
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Moderate", // Replace with actual UV index description
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
