import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/product/productFullView.dart';

import '../../models/Product.dart';
import 'SearchScreen.dart';

class SeeAllScreen extends StatefulWidget {
  const SeeAllScreen({super.key});


  @override
  State<SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends State<SeeAllScreen> {
  final List<Product> _products = [];
  bool _isLoading = false;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();

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
    await FirebaseFirestore.instance.collection('products').where('category',isNotEqualTo: "Rental").get();

    _products.addAll(
        querySnapshot.docs.map((doc) => Product.fromDocument(doc)).toList());
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
        .collection('products').where('category',isNotEqualTo: "Rental")
        .startAfterDocument(_lastDocument!)
        .limit(10)
        .get();

    _products.addAll(
        querySnapshot.docs.map((doc) => Product.fromDocument(doc)).toList());
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
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
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
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4 / 2,
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
    double rating = double.parse(product.avgRate);
    String formattedRating = rating.toStringAsFixed(1);
    double ratingToDouble = double.parse(formattedRating);
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context)=>Productfullview(imageUrls: product.imageUrl, productName: product.name, shortDescription: product.description, price: product.price, categoryName: product.category, sellerId: product.sellerId, isRental: product.isRental, id: product.id,rating: product.avgRate,quantity: product.quantity,)));
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
        margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10.0)),
              child: Image.network(
                product.imageUrl.first,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 130,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Text(
                product.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(ratingToDouble==5.0?Icons.star: ratingToDouble==0.0?Icons.star_border:Icons.star_half,color: Colors.green,),
                  Text(
                    formattedRating.toString(),
                    style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'PKR${product.price.toStringAsFixed(2)}/Kg',
                style: const TextStyle(fontSize: 16, color: Colors.green,fontWeight: FontWeight.bold),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
