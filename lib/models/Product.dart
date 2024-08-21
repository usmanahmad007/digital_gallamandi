import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String category; // New category field

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.category, // New category field
  });

  factory Product.fromDocument(DocumentSnapshot doc) {
    return Product(
      id: doc['productId'],
      name: doc['title'],
      description: doc['description'],
      imageUrl: doc['imageUrl'],
      price: double.parse(doc['price'].toString()),
      category: doc['category'], // New category field
    );
  }
}
