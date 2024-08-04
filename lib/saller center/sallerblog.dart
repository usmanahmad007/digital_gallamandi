import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class sallerBlogScreen extends StatefulWidget {
  const sallerBlogScreen({super.key});

  @override
  State<sallerBlogScreen> createState() => _sallerBlogScreenState();
}

class _sallerBlogScreenState extends State<sallerBlogScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "blog"
        ),
      ),
    );
  }
}
