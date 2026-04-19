import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/saller%20center/product/sallerProductFullView.dart';

import '../../models/Product.dart';
import 'EditProduct.dart';

// ... existing imports ...

class SallerProductListScreen extends StatefulWidget {
  const SallerProductListScreen({super.key});

  @override
  State<SallerProductListScreen> createState() => _SallerProductListScreenState();
}

class _SallerProductListScreenState extends State<SallerProductListScreen> {
  final CollectionReference productsRef = FirebaseFirestore.instance.collection('products');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Modern Snackbar with rounded edges
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Logic remains the same
  Future<void> _deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      _showSnackbar('Product deleted successfully', Colors.green.shade700);
    } catch (e) {
      _showSnackbar('Error deleting product: $e', Colors.redAccent);
    }
  }

  void _showDeleteConfirmationDialog(String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Product?'),
          content: const Text('This action cannot be undone. Do you want to remove this listing?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(productId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9), // Light modern background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'My Inventory',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: productsRef
            .where("sellerId", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products listed yet.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              // FIX: Type cast error solution
              final List<String> imageUrls = (data['imageUrls'] as List<dynamic>?)
                  ?.map((item) => item.toString())
                  .toList() ?? [];
              final List<String> rating = (data['rating'] as List<dynamic>?)
                  ?.map((item) => item.toString())
                  .toList() ?? [];

              print(imageUrls);
              final product = Product(
                  id: docs[index].id,
                  name: data['title'] ?? '',
                  description: data['description'] ?? '',
                  imageUrl: imageUrls,
                  avgRate: data['averageRating']?.toString() ?? '0.0',
                  price: double.tryParse(data['price'].toString()) ?? 0.0,
                  category: data['category'],
                  sellerId: data['sellerId'],
                  isRental: data['isRental'] ?? false,
                  rating: rating,
                  quantity: data['quantity']);

              return _buildModernProductCard(product);
            },
          );
        },
      ),
    );
  }

  // NEW: Refactored Modern UI Card
  Widget _buildModernProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SallerProductFullView(
                sellerId: product.sellerId,
                imageUrls: product.imageUrl,
                productName: product.name,
                shortDescription: product.description,
                price: product.price,
                categoryName: product.category,
                productId: product.id,
                isRental: product.isRental,
                rating: product.avgRate,
                isAdmin: false,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product.imageUrl.isNotEmpty ? product.imageUrl.first : '',
                  height: 90,
                  width: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Rs. ${product.price}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Row(
                          children: [
                            _actionIcon(Icons.edit_outlined, Colors.blue, () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EditProduct(productId: product.id)),
                              );
                            }),
                            const SizedBox(width: 8),
                            _actionIcon(Icons.delete_outline, Colors.redAccent, () {
                              _showDeleteConfirmationDialog(product.id);
                            }),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}