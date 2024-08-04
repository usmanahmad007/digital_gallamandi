import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class sallerOrdersscreen extends StatefulWidget {
  const sallerOrdersscreen({super.key});

  @override
  State<sallerOrdersscreen> createState() => _sallerOrdersscreenState();
}

class _sallerOrdersscreenState extends State<sallerOrdersscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Orders"
        ),
      ),
    );
  }
}
