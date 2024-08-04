import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_product_card/flutter_product_card.dart';
import 'package:zrai_mart/UI/productFullView.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
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
              return ProductCard(
                imageUrl: product['imageUrl'],
                productName: product['title'],
                shortDescription: product['description'],
                price: double.tryParse(product['price'].toString()) ?? 0.0,
                categoryName: 'Electronics',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Productfullview(
                        imageUrl: product['imageUrl'],
                        productName: product['title'],
                        shortDescription: product['description'],
                        price: double.tryParse(product['price'].toString()) ?? 0.0,
                        categoryName: 'Electronics', // Set appropriate categoryName
                      ),
                    ),
                  );
                  },
                onFavoritePressed: () {},
              );
            },
          );
        },
      ),
    );
  }
}
