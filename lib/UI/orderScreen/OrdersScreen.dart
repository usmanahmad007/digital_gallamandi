import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Ordersscreen extends StatefulWidget {
  const Ordersscreen({super.key});

  @override
  State<Ordersscreen> createState() => _OrdersscreenState();
}

class _OrdersscreenState extends State<Ordersscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Orders"),
      ),
    );
  }
}
