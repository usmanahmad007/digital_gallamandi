import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class wishListScreen extends StatefulWidget {
  const wishListScreen({super.key});

  @override
  State<wishListScreen> createState() => _wishListScreenState();
}

class _wishListScreenState extends State<wishListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Wish List"),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Text(
            "No Product Available"
          ),)
        ],
      ),
    );
  }
}
