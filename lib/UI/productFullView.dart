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
              Row(
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
              ),
              SizedBox(height: 16.0),
              Container(
                width: width/0.9,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Price: \$${totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    Container(
                      width: width/2.5,
                      child: ElevatedButton(
                        onPressed: _buyNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        child: Text('Buy Now',style: TextStyle(
                          color: Colors.black
                        ),),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.0),

            ],
          ),
        ),
      ),
    );
  }
}
