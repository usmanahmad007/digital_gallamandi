import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/product/productFullView.dart';

import '../../models/Product.dart';

class WishListScreen extends StatelessWidget {
  final String userId;

  const WishListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishList');

    final productRef = FirebaseFirestore.instance.collection('products');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final wishListDocs = snapshot.data!.docs;

          if (wishListDocs.isEmpty) {
            return const Center(child: Text('Your wishlist is empty.'));
          }

          return ListView.builder(
            itemCount: wishListDocs.length,
            itemBuilder: (context, index) {
              final productId = wishListDocs[index]['productId'];

              return FutureBuilder<DocumentSnapshot>(
                future: productRef.doc(productId).get(),
                builder: (context, productSnapshot) {
                  if (!productSnapshot.hasData) {
                    return const SizedBox(); // Or show a loading placeholder
                  }

                  final productData = productSnapshot.data!.data();
                  if (productData == null) return const SizedBox();

                  final product = Product.fromDocument(productSnapshot.data!);

                  return _buildProductItemWithRemove(product, userId, context);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductItemWithRemove(Product product, String userId, BuildContext context) {
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishList');

    double rating = double.parse(product.avgRate);
    String formattedRating = rating.toStringAsFixed(1);
    double ratingToDouble = double.parse(formattedRating);

    final width = MediaQuery.of(context).size.width;
    final List<String> imageUrls = List<String>.from(product.imageUrl ?? []);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Productfullview(
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
        width: width / 0.6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          color: Colors.white,
        ),
        margin: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10.0)),
                  child: Image.network(
                    imageUrls[0],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 130,
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    onPressed: () async {
                      try {
                        // Remove product from wishlist
                        await cartRef.doc(product.id).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} removed from wishlist'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error: Could not remove item'),
                          ),
                        );
                        print('Error removing item from wishlist: $e');
                      }
                    },
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Text(
                product.name,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Text(
                product.description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'PKR${product.price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(
                    ratingToDouble == 5.0
                        ? Icons.star
                        : ratingToDouble == 0.0
                        ? Icons.star_border
                        : Icons.star_half,
                    color: Colors.green,
                  ),
                  Text(
                    formattedRating.toString(),
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold),
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
