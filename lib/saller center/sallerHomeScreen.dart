import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/ProductListScreen.dart';

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
          GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>ProductListScreen()));
              },
              child: Icon(Icons.favorite, color: Colors.white,)
          ),
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
