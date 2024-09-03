import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class sallerHomescreen extends StatefulWidget {
  const sallerHomescreen({super.key});

  @override
  State<sallerHomescreen> createState() => _sallerHomescreenState();
}

class _sallerHomescreenState extends State<sallerHomescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        actions: [
          SizedBox(width: 10,),

          const SizedBox(width: 10,),
          Icon(Icons.notifications_active, color: Colors.white,),
          SizedBox(width: 10,),



        ],
        title: Text('Digital Galla Mandi',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),

      ),
      body: Center(
        child: Text("Hello"),
      ),
    );
  }
}
