import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final List<String> imageUrl;
  final double price;
  final String category; // New category field
  final String sellerId;
  final bool isRental;
  final List<String> rating;
  final String avgRate;
  final String quantity;


  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.category, // New category field
    required this.sellerId,
    required this.isRental,required this.rating, required this.avgRate, required this.quantity
  });

  factory Product.fromDocument(DocumentSnapshot doc) {
    return Product(
      id: doc.id,
      name: doc['title'],
      quantity: doc['quantity'],
      description: doc['description'],
      imageUrl:List<String>.from(doc['imageUrls'] ?? []),
      price: double.parse(doc['price'].toString()),
      avgRate: doc['averageRating'].toString(),
      category: doc['category'], sellerId: doc['sellerId'], isRental:doc['isRental'], rating: List<String>.from(doc['rating'] ?? [],) // New category field
    );
  }
}
