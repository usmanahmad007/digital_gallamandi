import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/WeatherMoreDetail.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
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
        child: Center(
          child: Column(children: [
            SizedBox(
              height: 10,
            ),
            Container(
                width: 120, height: 80, child: Image.asset("assets/cloud.png")),
            Text(
              "190",
              style: TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold, fontSize: 28),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "Gujranwala",
              style: TextStyle(color: Colors.green, fontSize: 16),
            ),
            Text(
              "Max: 24  Min: 18",
              style: TextStyle(
                color: Colors.green,
              ),
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
                        Text("Today",style: TextStyle(color: Colors.white54),),
                        Text("July 21",style: TextStyle(color: Colors.white54),),
        
                      ],
                    ),
                  ),
                  SizedBox(height: 3,),
                  Container(
                    width: width / 1.3,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white
                    ),
                  ),
                  SizedBox(height: 15,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text("19",style: TextStyle(
                              color: Colors.white54
                            ),),
                            Image.asset("assets/iconweather.png",width: 60,height: 60,),
                            Text("15.00",style: TextStyle(
                                color: Colors.white54
                            ),)
                          ],
                        ),
                      ),Center(
                        child: Column(
                          children: [
                            Text("19",style: TextStyle(
                                color: Colors.white54
                            ),),
                            Image.asset("assets/iconweather.png",width: 60,height: 60,),
                            Text("15.00",style: TextStyle(
                                color: Colors.white54
                            ),)
                          ],
                        ),
                      ),Center(
                        child: Column(
                          children: [
                            Text("19",style: TextStyle(
                                color: Colors.white54
                            ),),
                            Image.asset("assets/iconweather.png",width: 60,height: 60,),
                            Text("15.00",style: TextStyle(
                                color: Colors.white54
                            ),)
                          ],
                        ),
                      ),Center(
                        child: Column(
                          children: [
                            Text("19",style: TextStyle(
                                color: Colors.white54
                            ),),
                            Image.asset("assets/iconweather.png",width: 60,height: 60,),
                            Text("15.00",style: TextStyle(
                                color: Colors.white54
                            ),)
                          ],
                        ),
                      )
                    ],
                  ),

                ],
              ),
            ),
            SizedBox(height: 40,),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap:(){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>WeatherMoreDetrail()));
                    },
                    child: Container(
                      width:150,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(25)
                      ),
                      child: Center(child: Text("More Details",style: TextStyle(
                        color: Colors.white,fontSize: 12
                      ),)),
                    ),
                  ),Container(
                    width:150,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(25)
                    ),
                    child: Center(child: Text("Get Recomendation",style: TextStyle(
                      color: Colors.white,fontSize: 12
                    ),)),
                  ),

                ],
              ),
            )
          ]
          ),
        ),
      ),
    );
  }
}
