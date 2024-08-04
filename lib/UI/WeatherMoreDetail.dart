import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WeatherMoreDetrail extends StatefulWidget {
  const WeatherMoreDetrail({super.key});

  @override
  State<WeatherMoreDetrail> createState() => _WeatherMoreDetrailState();
}

class _WeatherMoreDetrailState extends State<WeatherMoreDetrail> {
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> weatherData = List.generate(10, (index) {
    final random = Random();
    return {
      "temperature":
          random.nextInt(35) + 10, // Random temperature between 10 and 45
      "icon": "assets/iconweather.png", // Path to weather icon
      "time":
          "${random.nextInt(23).toString().padLeft(2, '0')}:00", // Random time
    };
  });
  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 100, // Scroll left by 100 pixels
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 100, // Scroll right by 100 pixels
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 50,
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Gujranwala Pakistan",style:
                  TextStyle(color: Colors.green, fontSize: 16,),),
                  Text("Max:24 Min:18",style:
                  TextStyle(color: Colors.green, fontSize: 16,),),
                ],
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Row(
              children: [
                SizedBox(width: 50),
                Text("7-Days Forecasts",style:
                    TextStyle(color: Colors.green, fontSize: 16,fontWeight: FontWeight.bold),),
              ],
            ),
            SizedBox(
              height: 20,
            ),
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
                        height: 150, // Set the height of the slider
                        width: 250, // Set the width of the slider
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: weatherData
                              .length, // Number of items in the slider
                          itemBuilder: (context, index) {
                            final data = weatherData[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
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
                                      "${data['temperature']}°C",
                                      style: TextStyle(
                                        color: Colors.white54,
                                      ),
                                    ),
                                    Image.asset(
                                      data['icon'],
                                      width: 60,
                                      height: 60,
                                    ),
                                    Text(
                                      data['time'],
                                      style: TextStyle(
                                        color: Colors.white54,
                                      ),
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
            SizedBox(
              height: 20,
            ),
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
                      Container(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_searching,
                              color: Colors.white,
                              size: 25,
                            ),
                            SizedBox(width: 5,),
                            Text(
                              "AIR QUALITY",
                              style:
                                  TextStyle(color: Colors.white60, fontSize: 12),
                            )
                          ],
                        ),

                      ),
                      SizedBox(height: 10,),
                      Row(
                        children: [
                          Text("3-LOW HEALTH RISK",style:
                          TextStyle(color: Colors.white, fontSize: 18,fontWeight: FontWeight.bold),),
                        ],
                      ),
                      Container(
                        width: width / 1.5,
                        height: 4,
                        color: Colors.white,
                      ),
                      SizedBox(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("See more",style:
                          TextStyle(color: Colors.white, fontSize: 14,),),
                          Icon(Icons.chevron_right,size: 30,color: Colors.white,)
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 30,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: EdgeInsets.all(10),
                  width: 120,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(15)
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(Icons.sunny,color: Colors.yellow,),
                            Text("SUNRISE",
                                style: TextStyle(
                                color: Colors.white54,
                                  fontSize: 12
                            ),)
                          ],
                        ),
                      ),
                      Text("5:38AM",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
                      Text("Sunset: 7:25AM",
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12
                        ),)
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(10),
                  width: 120,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(15)
                  ),
                  child: Column(

                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(Icons.sunny,color: Colors.yellow,),
                            Text("UVINDEX",
                                style: TextStyle(
                                color: Colors.white54,
                                  fontSize: 12
                            ),)
                          ],
                        ),
                      ),
                      Text("4",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
                      Text("Modeate",
                        style: TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold
                        ),)
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
