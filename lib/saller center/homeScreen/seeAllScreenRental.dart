import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/saller%20center/homeScreen/productFullView.dart';

import '../../models/Product.dart';

class SeeAllScreenRental extends StatefulWidget {
  const SeeAllScreenRental({super.key});


  @override
  State<SeeAllScreenRental> createState() => _SeeAllScreenRentalState();
}

class _SeeAllScreenRentalState extends State<SeeAllScreenRental> {
  final List<Product> _products = [];
  bool _isLoading = false;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth=FirebaseAuth.instance;


  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent &&
          !_isLoading) {
        _loadMoreProducts();
      }
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('products').where('category',isEqualTo: "Rental").get();

    _products.addAll(
        querySnapshot.docs.map((doc) => Product.fromDocument(doc)).where((product)=> product.sellerId!= _auth.currentUser!.uid).toList());
    _lastDocument =
    querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMoreProducts() async {
    if (_lastDocument == null) return;

    setState(() {
      _isLoading = true;
    });

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('products').where("category",isEqualTo: "Rental")
        .startAfterDocument(_lastDocument!)
        .limit(10)
        .get();

    _products.addAll(
        querySnapshot.docs.map((doc) => Product.fromDocument(doc)).where((product)=> product.sellerId!= _auth.currentUser!.uid).toList());
    _lastDocument =
    querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Products"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            const SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  /*GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchScreen()),
                      );
                    },
                    child: Container(
                      height: 55,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Icon(Icons.filter_list, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),*/
                  SizedBox(height: 20),
                ],
              ),
            ),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3 / 2,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return _buildProductItem(_products[index]);
                },
                childCount: _products.length,
              ),
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context)=>Productfullview(imageUrls: product.imageUrl, productName: product.name, shortDescription: product.description, price: product.price, categoryName: product.category,  isRental: product.isRental,rating: product.avgRate, productId: product.id,)));
      },
      child: Container(
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10.0)),
              child: Image.network(
                product.imageUrl.first,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 150,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
