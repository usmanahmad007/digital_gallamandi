import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/saller%20center/EditProduct.dart';

class SallerProductFullView extends StatefulWidget {
  final String imageUrl;
  final String productName;
  final String shortDescription;
  final double price;
  final String categoryName;
  final String productId;

  const SallerProductFullView({
    Key? key,
    required this.imageUrl,
    required this.productName,
    required this.shortDescription,
    required this.price,
    required this.categoryName,
    required this.productId,
  }) : super(key: key);

  @override
  _ProductfullviewState createState() => _ProductfullviewState();
}

class _ProductfullviewState extends State<SallerProductFullView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _quantity = 1;

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
      }
    });
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


  void _buyNow() {
    // Handle the buy now action
    // You might want to navigate to another screen or show a confirmation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Buying ${widget.productName} x$_quantity'),
        backgroundColor: Colors.green,
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
  void _uploadProduct() async {

try{
  // Upload product data to Firestore
  FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).collection("addToCart").add({
    'title': widget.productName,
    'description': widget.shortDescription,
    'price': widget.price,
    'imageUrl': widget.imageUrl,
    'quantity': 1,
  });
  _showSnackbar('Product uploaded successfully', Colors.green);
}catch(e){
  _showSnackbar('Product add to cart failed', Colors.red);
}





  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.price * _quantity;
    final width=MediaQuery.of(context).size.width;

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
              Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                height: 300.0,
                width: double.infinity,
              ),
              SizedBox(height: 16.0),
              Text(
                widget.productName,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                widget.categoryName,
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                '\$${widget.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                widget.shortDescription,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16.0),
              /*Row(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: _decrementQuantity,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 5,),
                  Container(
                    width: 50,
                    height: 47,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                      ),
                      borderRadius: BorderRadius.circular(5)
                    ),
                    child: Center(
                      child: Text(
                        '$_quantity',
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
                  ),
                  SizedBox(width: 5,),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _incrementQuantity,
                    ),
                  ),
                ],
              ),*/
              /*Text(
                'Total Price: \$${totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),*/
              SizedBox(height: 16.0),


              SizedBox(height: 16.0),

            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(10),
        width: width/0.9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Container(
              width: width/2.2,
              child: ElevatedButton(
                onPressed: (){
                  print(widget.productId);
                  _showDeleteConfirmationDialog(widget.productId);

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Text('Delete',style: TextStyle(
                    color: Colors.red
                ),),
              ),
            ),Container(
              width: width/2.2,
              child: ElevatedButton(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>EditProduct(productId: widget.productId)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Text('Edit',style: TextStyle(
                    color: Colors.black
                ),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
