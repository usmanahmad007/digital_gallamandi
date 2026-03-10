import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'AdminProductFullView.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  _AdminProductsScreenState createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width=MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by product title...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          final products = snapshot.data!.docs.where((doc) {
            final title = doc['title'].toString().toLowerCase();
            return title.contains(_searchQuery);
          }).toList();

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final productId = product.id;
              final imageUrls = List<String>.from(product['imageUrls'] ?? []);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      height: 400,
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminProductFullView(
                                  imageUrls: imageUrls,
                                  productName: product['title'],
                                  shortDescription: product['description'],
                                  price: double.parse(product['price']),
                                  categoryName: product['category'],
                                  productId: productId,
                                  isRental: product['isRental'],
                                  rating: product['averageRating'].toString(),
                                  isAdmin: true,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image Carousel for multiple images
                              Expanded(
                                child: PageView.builder(
                                  itemCount: imageUrls.length,
                                  itemBuilder: (context, index) {
                                    return Image.network(
                                      imageUrls[index],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['title'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      product['category'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'PKR ${double.parse(product['price'])}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      product['description'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black.withOpacity(0.7),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    product['isRental'] == false
                                        ? Row(
                                            children: [
                                              Icon(
                                                double.parse(product[
                                                                'averageRating']
                                                            .toString()) ==
                                                        5.0
                                                    ? Icons.star
                                                    : double.parse(product[
                                                                    'averageRating']
                                                                .toString()) ==
                                                            0.0
                                                        ? Icons.star_border
                                                        : Icons.star_half_sharp,
                                                color: Colors.green,
                                              ),
                                              Text(
                                                product['averageRating']
                                                    .toString(),
                                                style: TextStyle(
                                                  fontSize: 22.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                            ],
                                          )
                                        : Container(),
                                    const SizedBox(height: 10,),
                                    SizedBox(
                                      width: width / 0.9,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showDeleteConfirmationDialog(productId);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20.0),
                                          ),
                                        ),
                                        child: const Text('Delete',
                                            style: TextStyle(
                                              color: Colors.red,
                                            )),
                                      ),
                                    ),

                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  /*AdminProductCard(
                    imageUrls: imageUrls,
                    categoryName: product['category'],
                    productName: product['title'],
                    price: double.parse(product['price']),
                    onTap: () {
                      // Navigate to the full view if needed
                    },
                    shortDescription: product['description'],
                    productId: productId,
                    rating: double.parse(product['averageRating'].toString()),
                    isRental: product['isRental'],
                  ),*/
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: const Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(productId);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
