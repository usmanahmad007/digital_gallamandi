import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/Product.dart';
import 'EditProduct.dart';

class SallerProductListScreen extends StatefulWidget {
  @override
  State<SallerProductListScreen> createState() => _SallerProductListScreenState();
}

class _SallerProductListScreenState extends State<SallerProductListScreen> {
  final CollectionReference productsRef =
  FirebaseFirestore.instance.collection('products');

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      _showSnackbar('Product deleted successfully', Colors.green);
    } catch (e) {
      _showSnackbar('Error deleting product: $e', Colors.red);
    }
  }

  void _showDeleteConfirmationDialog(String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Text('Delete Product'),
              Icon(Icons.delete, color: Colors.red, size: 30),
            ],
          ),
          content: Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No', style: TextStyle(color: Colors.black)),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteProduct(productId);
                },
                child: Text('Yes', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Products'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: productsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Nothing to show'));
          }

          final products = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Product(
              id: doc.id,
              name: data['title'] ?? '',
              description: data['description'] ?? '',
              imageUrl: data['imageUrl'] ?? '',
              price: double.tryParse(data['price'].toString()) ?? 0.0, category: data['category'],
            );
          }).toList();

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final productId=product.id;
              return Padding(
                padding: EdgeInsets.all(10),
                child: Container(

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.green.shade300,

                  ),
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Column(
                      children: [
                        Text(product.description),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("PKR: "+product.price.toString()),
                            Container(child: Row(
                              children: [
                                IconButton(onPressed: (){
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditProduct(productId: productId),
                                    ),
                                  );
                                }, icon: Icon(Icons.edit_note)),
                                IconButton(onPressed: (){
                                  _showDeleteConfirmationDialog(productId);

                                }, icon: Icon(Icons.delete,color: Colors.red,)),


                              ],
                            ))
                          ],
                        ),

                      ],
                    ),
                    leading: Image.network(product.imageUrl),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}