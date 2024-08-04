import 'package:flutter/material.dart';


import '../models/Product.dart';

class Cartscreen extends StatefulWidget {
  const Cartscreen({super.key});

  @override
  State<Cartscreen> createState() => _CartscreenState();
}

class _CartscreenState extends State<Cartscreen> {
  final List<Product> productList = [
    Product(
      id: '1',
      name: 'Product 1',
      description: 'Description of Product 1',
      imageUrl: 'https://via.placeholder.com/150',
      price: 0.0,
    ),
    Product(
      id: '2',
      name: 'Product 2',
      description: 'Description of Product 2',
      imageUrl: 'https://via.placeholder.com/150',
      price: 0.0,
    ),
    // Add more products as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
      ),
      body: Center(
        child: Text(
          "Card SCreen"
        ),
      ),
    );
  }
}
