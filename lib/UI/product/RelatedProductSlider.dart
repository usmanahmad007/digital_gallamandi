import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zrai_mart/UI/product/CustomerProductFullView.dart';

class RelatedProductsSlider extends StatefulWidget {
  final String category;
  final String currentProductId;

  const RelatedProductsSlider({
    super.key,
    required this.category,
    required this.currentProductId,
  });

  @override
  _RelatedProductsSliderState createState() => _RelatedProductsSliderState();
}

class _RelatedProductsSliderState extends State<RelatedProductsSlider> {
  late Future<List<Map<String, dynamic>>> _relatedProductsFuture;

  @override
  void initState() {
    super.initState();
    _relatedProductsFuture = _fetchRelatedProducts();
  }

  Future<List<Map<String, dynamic>>> _fetchRelatedProducts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('category', isEqualTo: widget.category)
        .orderBy('averageRating', descending: true)
        .limit(10)
        .get();

    return snapshot.docs
        .where((doc) => doc.id != widget.currentProductId)
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _relatedProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator(color: Colors.green)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Hide if nothing is found
        }

        final relatedProducts = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
              child: Text(
                "Related Products",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 270.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: relatedProducts.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final product = relatedProducts[index];
                  final isRental = product['isRental'] ?? false;
                  final String priceUnit = isRental ? "/hr" : "/kg";

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => customerProductfullview(
                            id: product['id'],
                            imageUrls: List<String>.from(product['imageUrls']),
                            productName: product['title'],
                            shortDescription: product['description'],
                            price: double.parse(product['price'].toString()),
                            categoryName: product['category'],
                            sellerId: product['sellerId'],
                            isRental: isRental,
                            rating: product['averageRating'].toString(),
                            quantity: product['quantity'].toString(),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 170,
                      margin: const EdgeInsets.only(right: 16.0, bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- IMAGE ---
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(
                              product['imageUrls'][0],
                              height: 140.0,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: Colors.grey[100], child: const Icon(Icons.broken_image)),
                            ),
                          ),

                          // --- CONTENT ---
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['title'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                if (!isRental)
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${product['averageRating']}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      'PKR ${product['price']}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      priceUnit,
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
                },
              ),
            ),
          ],
        );
      },
    );
  }
}