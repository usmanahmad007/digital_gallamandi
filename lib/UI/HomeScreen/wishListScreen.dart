import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/product/CustomerProductFullView.dart';
import '../../models/Product.dart';

class WishListScreen extends StatelessWidget {
  final String userId;

  const WishListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final wishListRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishList');

    final productRef = FirebaseFirestore.instance.collection('products');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'My Wishlist',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: wishListRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          final wishListDocs = snapshot.data?.docs ?? [];

          if (wishListDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Your wishlist is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: wishListDocs.length,
            itemBuilder: (context, index) {
              final productId = wishListDocs[index]['productId'];

              return FutureBuilder<DocumentSnapshot>(
                future: productRef.doc(productId).get(),
                builder: (context, productSnapshot) {
                  if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                    return const SizedBox();
                  }

                  final product = Product.fromDocument(productSnapshot.data!);
                  return _buildWishlistCard(product, userId, context);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWishlistCard(Product product, String userId, BuildContext context) {
    final wishListRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishList');

    final List<String> imageUrls = List<String>.from(product.imageUrl ?? []);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => customerProductfullview(
              imageUrls: product.imageUrl,
              productName: product.name,
              shortDescription: product.description,
              price: product.price,
              categoryName: product.category,
              sellerId: product.sellerId,
              isRental: product.isRental,
              id: product.id,
              rating: product.avgRate,
              quantity: product.quantity,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- IMAGE SECTION WITH ACTIONS ---
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.network(
                      imageUrls.isNotEmpty ? imageUrls[0] : "",
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                    ),
                  ),
                  // Rental Badge
                  if (product.isRental)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "RENTAL",
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  // Remove Button
                  Positioned(
                    top: 5,
                    right: 5,
                    child: IconButton(
                      onPressed: () async {
                        await wishListRef.doc(product.id).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Removed from wishlist'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.favorite, color: Colors.green, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- INFO SECTION ---
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.category,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PKR ${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if(product.isRental==false)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            product.avgRate,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
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
    );
  }
}