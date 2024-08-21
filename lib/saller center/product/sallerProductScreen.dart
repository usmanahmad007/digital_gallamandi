import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zrai_mart/saller%20center/product/EditProduct.dart';
import 'package:zrai_mart/saller%20center/product/addProduct.dart';
import 'package:zrai_mart/saller%20center/product/sallerProductFullView.dart';
import 'package:zrai_mart/saller%20center/product/sallerProductListScreen.dart';
import '../../product card/sallerProductCard.dart';

class sallerProductScreen extends StatefulWidget {
  const sallerProductScreen({super.key});

  @override
  State<sallerProductScreen> createState() => _sallerProductScreenState();
}

class _sallerProductScreenState extends State<sallerProductScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> imageSliders = [];

  @override
  void initState() {
    super.initState();
    fetchDataFromFirebase();
  }

  Future<void> fetchDataFromFirebase() async {
    try {
      // Fetch slider images from Firestore
      CollectionReference collectionRef =
          FirebaseFirestore.instance.collection('slider');
      QuerySnapshot querySnapshot = await collectionRef.get();

      setState(() {
        imageSliders =
            querySnapshot.docs.map((doc) => doc['image1'] as String).toList();
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
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
        title: Text('Seller Center'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Addproduct()),
              );
            },
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10),
            imageSliders.isNotEmpty
                ? CarouselSlider(
                    options: CarouselOptions(
                      aspectRatio: 2.0,
                      enlargeCenterPage: true,
                      scrollDirection: Axis.horizontal,
                      autoPlay: true,
                    ),
                    items: imageSliders.map((item) {
                      return Container(
                        child: Center(
                          child: Image.network(
                            item,
                            fit: BoxFit.cover,
                            width: 1000,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : Container(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
            SizedBox(height: 10),
            Container(
              height: 40,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.7),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Your Products",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SallerProductListScreen()));
                    },
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Text(
                            "see all",
                            style: TextStyle(color: Colors.white),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_sharp,
                            color: Colors.white,
                            size: 12,
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('products')
                  .where('sellerId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final products = snapshot.data!.docs;
                print("gift");
                print(snapshot);
                print(snapshot.data!.docs);

                if (products.isEmpty) {
                  return Center(child: Text('No products available'));
                }

                return Column(
                  children: products.map((productDoc) {
                    final product = productDoc.data() as Map<String, dynamic>;
                    final productId = productDoc.id;

                    return GestureDetector(
                      onDoubleTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProduct(productId: productId),
                          ),
                        );
                      },
                      onLongPress: () {
                        _showDeleteConfirmationDialog(productId);
                      },
                      child: sallerProductCard(
                        imageUrl: product['imageUrl'],
                        productName: product['title'],
                        shortDescription: product['description'],
                        price:
                            double.tryParse(product['price'].toString()) ?? 0.0,
                        categoryName: product['category'],
                        productId: productId,
                        onTap: () {
                          //  Navigator.push(context, MaterialPageRoute(builder: (context)=>SallerProductFullView(imageUrl: product['imageUrl'], productName: product['title'], shortDescription: product['description'], price: product['price'], categoryName: product['category'])));
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
