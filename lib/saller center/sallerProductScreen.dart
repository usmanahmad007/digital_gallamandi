import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zrai_mart/saller%20center/addProduct.dart';
import '../product card/sallerProductCard.dart';

class sallerProductScreen extends StatefulWidget {
  const sallerProductScreen({super.key});

  @override
  State<sallerProductScreen> createState() => _sallerProductScreenState();
}

class _sallerProductScreenState extends State<sallerProductScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seller Products'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Addproduct()));
            },
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return Center(child: Text('No products available'));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;
              return sallerProductCard(
                imageUrl: product['imageUrl'],
                productName: product['title'],
                shortDescription: product['description'],
                price: double.tryParse(product['price'].toString()) ?? 0.0, categoryName: '', onTap: () {  },
              );
            },
          );
        },
      ),
    );
  }
}
