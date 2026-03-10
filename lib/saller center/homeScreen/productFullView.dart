import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../UI/product/ProductReviewsWidget.dart';
import '../../UI/product/RelatedProductSlider.dart';

class Productfullview extends StatefulWidget {
  final List<String> imageUrls; // Changed to a list of image URLs
  final String productName;
  final String shortDescription;
  final double price;
  final String categoryName;
  final String productId;
  final bool isRental;
  final String rating;
  final bool? isAdmin;

  const Productfullview({
    super.key,
    required this.imageUrls,
    required this.productName,
    required this.shortDescription,
    required this.price,
    required this.categoryName,
    required this.productId, required this.isRental, required this.rating, this.isAdmin=false,

  });

  @override
  _ProductfullviewState createState() => _ProductfullviewState();
}

class _ProductfullviewState extends State<Productfullview> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          title: const Row(
            children: [
              Text('Delete Product'),
              Icon(Icons.delete, color: Colors.red, size: 30),
            ],
          ),
          content: const Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No', style: TextStyle(color: Colors.black)),
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
                child: const Text('Yes', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        );
      },
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productName),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 300.0,
                child: PageView.builder(
                  itemCount: widget.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                widget.productName,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                widget.categoryName,
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'PKR: ${widget.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              widget.isRental==false?Row(
                children: [
                  Icon(widget.rating=='5.0'? Icons.star: widget.rating=='0.0'? Icons.star_border:Icons.star_half_sharp,color: Colors.green,),
                  Text(
                    widget.rating,
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ): Container(),
              const SizedBox(height: 16.0),
              Text(
                widget.shortDescription,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 20,),
              widget.isRental==false?
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  "Recommended",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ):const Text(''),
              const SizedBox(height: 20,),
              widget.isRental==false?RelatedProductsSlider(
                  category: widget.categoryName.toString(),
                  currentProductId: widget.productId.toString()):Container(),
              const SizedBox(height: 20,),
              widget.isRental==false?
              ProductReviewsWidget(productId: widget.productId.toString()): Container(),
            ],
          ),
        ),
      ),
      /*bottomNavigationBar: Container(
        padding: const EdgeInsets.all(10),
        width: width / 0.9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width:  widget.isAdmin==true? width/1.1: width / 2.2,
              child: ElevatedButton(
                onPressed: () {
                  _showDeleteConfirmationDialog(widget.productId);
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
            widget.isAdmin==false? SizedBox(
              width: width / 2.2,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              EditProduct(productId: widget.productId)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: const Text('Edit',
                    style: TextStyle(
                      color: Colors.black,
                    )),
              ),
            ):const SizedBox(),
          ],
        ),
      ),*/
    );
  }
}
