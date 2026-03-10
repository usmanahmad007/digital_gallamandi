import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/stripeService/stripe_service.dart';

class DeliveryFormScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> cartItems;
  final String totalAmount;

  const DeliveryFormScreen({super.key, required this.cartItems, required this.totalAmount});

  @override
  _DeliveryFormScreenState createState() => _DeliveryFormScreenState();
}

class _DeliveryFormScreenState extends State<DeliveryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _postalCodeFocusNode = FocusNode();

  String? _selectedCity;
  bool loading=false;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      loading=false;
    });
  }
  final List<String> _cities = [
    // Punjab
    'Punjab - Lahore',
    'Punjab - Faisalabad',
    'Punjab - Rawalpindi',
    'Punjab - Multan',
    'Punjab - Gujranwala',
    'Punjab - Sialkot',
    'Punjab - Bahawalpur',
    'Punjab - Sargodha',
    'Punjab - Sheikhupura',
    'Punjab - Gujrat',
    'Punjab - Kasur',
    'Punjab - Rahim Yar Khan',
    'Punjab - Sahiwal',
    'Punjab - Okara',
    'Punjab - Jhelum',
    'Punjab - Mianwali',
    'Punjab - Dera Ghazi Khan',
    'Punjab - Chakwal',
    'Punjab - Narowal',
    'Punjab - Attock',
    'Punjab - Islamabad',

    // Gilgit-Baltistan
    'Gilgit-Baltistan - Gilgit',
    'Gilgit-Baltistan - Skardu',
    'Gilgit-Baltistan - Hunza',
    'Gilgit-Baltistan - Ghizer',
    'Gilgit-Baltistan - Ghanche',
    'Gilgit-Baltistan - Nagar',

    // Azad Jammu and Kashmir (AJK)
    'AJK - Muzaffarabad',
    'AJK - Mirpur',
    'AJK - Kotli',
    'AJK - Bhimber',
    'AJK - Bagh',
    'AJK - Rawalakot',
    'AJK - Sudhanoti',

    // Khyber Pakhtunkhwa (KPK)
    'KPK - Peshawar',
    'KPK - Abbottabad',
    'KPK - Mardan',
    'KPK - Swat (Mingora)',
    'KPK - Kohat',
    'KPK - Dera Ismail Khan',
    'KPK - Charsadda',
    'KPK - Mansehra',
    'KPK - Bannu',
    'KPK - Nowshera',

    // Sindh
    'Sindh - Karachi',
    'Sindh - Hyderabad',
    'Sindh - Sukkur',
    'Sindh - Larkana',
    'Sindh - Nawabshah',
    'Sindh - Mirpurkhas',
    'Sindh - Khairpur',
    'Sindh - Jacobabad',
    'Sindh - Shikarpur',

    // Balochistan
    'Balochistan - Quetta',
    'Balochistan - Gwadar',
    'Balochistan - Turbat',
    'Balochistan - Khuzdar',
    'Balochistan - Sibi',
    'Balochistan - Chaman',
    'Balochistan - Zhob',
    'Balochistan - Panjgur',
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Full Name TextFormField
                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person, color: Colors.grey),
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: _nameFocusNode.hasFocus
                        ? Colors.greenAccent.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // City Dropdown
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCity,
                        decoration: InputDecoration(
                          labelText: 'City',
                          prefixIcon: const Icon(Icons.location_city, color: Colors.grey),
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.green),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20),
                          errorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.red),
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        items: _cities
                            .map((city) => DropdownMenuItem(
                          value: city,
                          child: Text(
                            city,
                            overflow: TextOverflow.ellipsis, // Prevents long text from overflowing
                            maxLines: 1,
                          ),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your city';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),


                const SizedBox(height: 20),

                // Address TextFormField
                TextFormField(
                  controller: _addressController,
                  focusNode: _addressFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Shipping Address',
                    prefixIcon:
                        const Icon(Icons.location_on, color: Colors.grey),
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: _addressFocusNode.hasFocus
                        ? Colors.greenAccent.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Phone Number TextFormField
                TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: _phoneFocusNode.hasFocus
                        ? Colors.greenAccent.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                TextFormField(
                  controller: _postalCodeController,
                  focusNode: _postalCodeFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Postal Code',
                    prefixIcon:
                        const Icon(Icons.local_post_office, color: Colors.grey),
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: _postalCodeFocusNode.hasFocus
                        ? Colors.greenAccent.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your postal code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Submit Button
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() {
                        loading = true;
                      });



                        getPaymentResponce();


                      // After payment response, set loading to false

                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill the form')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Button color
                    minimumSize: Size(width, 50), // Set the width and height
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Center(
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text(
                      "Buy Now",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                )


              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitOrder(BuildContext context) async {
    try {
      final ordersRef = FirebaseFirestore.instance.collection('orders');
      final userId = FirebaseAuth.instance.currentUser?.uid;
    //  bool paymentPaid=getPaymentResponce();


      for (var cartItem in widget.cartItems) {
        await decreaseProductQuantity(cartItem['productId'],cartItem['quantity']);

        final List<String> imageUrls =
            List<String>.from(cartItem['imageUrl'] ?? []);
        final orderId = ordersRef.doc().id; // Generate a unique order ID


        final orderData = {
          'orderId': orderId,
          'userId': userId,
          'productId': cartItem['productId'],
          'title': cartItem['title'],
          'quantity': cartItem['quantity'],
          'price': cartItem['price'],
          'sellerId': cartItem['sallerId'],
          'isRental': cartItem['isRental'],
          'status': 'pending',
          'image': imageUrls.isNotEmpty ? imageUrls[0] : null,
          'totalPrice': (cartItem['price'] as double) *
              (cartItem['quantity'] as int).toDouble(),
          'orderDate': DateTime.now(),
          'timestamp': FieldValue.serverTimestamp(),
          'name': _nameController.text,
          'address': _addressController.text,
          'phoneNumber': _phoneController.text,
          'postalCode': _postalCodeController.text,
          'city': _selectedCity,
          'receiptImage':'pending',
          'rated': false,
        };



        await ordersRef.doc(orderId).set(orderData);
      }

      // Clear the cart after placing the order
      for (var cartItem in widget.cartItems) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('addToCart')
            .doc(cartItem.id)
            .delete();
      }

      Navigator.pop(context); // Close the delivery form
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    }
  }
  Future<void> decreaseProductQuantity(String productId,int quantity) async {
    print("${productId}HUKOM$quantity");
    try {
      CollectionReference products = FirebaseFirestore.instance.collection('products');

      // Fetch the current quantity
      DocumentSnapshot snapshot = await products.doc(productId).get();

      if (snapshot.exists) {
        int currentQuantity = int.parse(snapshot['quantity'] ?? 0);
        print("${currentQuantity}HUKAM");
        if (currentQuantity > 0) {
          // Update the quantity in Firestore
          await products.doc(productId).update({'quantity': (currentQuantity - quantity).toString()});
          print('Quantity updated successfully');
        } else {
          print('Quantity is already 0');
        }
      } else {
        print('Product does not exist');
      }
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }
  void getPaymentResponce() async {

    int totalIntAmount = double.parse(widget.totalAmount.toString()).toInt();
    bool flag=await StripeService.instance.makePayment(totalIntAmount);
    print("Gift$flag");
    if(flag==true){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful')),
      );
      _submitOrder(context);


    }  else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order: Payment Error!')),
      );
    }
    setState(() {
      loading = false;
    });

  }

}
