import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Productfullview extends StatefulWidget {
  final String imageUrl;
  final String productName;
  final String shortDescription;
  final double price;
  final String categoryName;

  const Productfullview({
    Key? key,
    required this.imageUrl,
    required this.productName,
    required this.shortDescription,
    required this.price,
    required this.categoryName,
  }) : super(key: key);

  @override
  _ProductfullviewState createState() => _ProductfullviewState();
}

class _ProductfullviewState extends State<Productfullview> {
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
    'category': widget.categoryName,
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
                onPressed: _buyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Text('Buy now',style: TextStyle(
                    color: Colors.green
                ),),
              ),
            ),Container(
              width: width/2.2,
              child: ElevatedButton(
                onPressed: _uploadProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Text('Add to cart',style: TextStyle(
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
