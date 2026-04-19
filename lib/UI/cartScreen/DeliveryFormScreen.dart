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
  final _couponController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _postalCodeFocusNode = FocusNode();

  String? _selectedCity;
  bool loading = false;

  // --- Coupon State Variables ---
  double _discountAmount = 0.0;
  String? _appliedCouponId;
  bool _isCouponApplied = false;
  bool _validatingCoupon = false;

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
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _postalCodeController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  // --- Coupon Logic ---
  Future<void> _applyCoupon() async {
    if (_couponController.text.isEmpty) return;

    setState(() => _validatingCoupon = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('coupons')
          .where('couponCode', isEqualTo: _couponController.text.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _showSnackBar("Coupon not found.", isError: true);
        return;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      final String couponSellerId = data['sellerId'] ?? ""; // The seller who owns the coupon

      // --- NEW SELLER VERIFICATION LOGIC ---
      // Check if every item in the cart belongs to this coupon's seller
      bool allItemsMatchSeller = widget.cartItems.every((item) {
        // Using 'sallerId' as per your _submitOrder code
        return item['sallerId'] == couponSellerId;
      });

      if (!allItemsMatchSeller) {
        _showErrorDialog(
            "Invalid Store",
            "This coupon is only valid for items from a specific store. Please remove items from other sellers to use this discount."
        );
        return;
      }
      // -------------------------------------

      final DateTime expireDate = (data['expireDate'] as Timestamp).toDate();
      final bool isEnabled = data['isEnabled'] ?? true;

      if (!isEnabled) {
        _showSnackBar("This coupon is currently disabled by the seller.", isError: true);
        return;
      }

      if (DateTime.now().isAfter(expireDate)) {
        _showSnackBar("This coupon has expired.", isError: true);
        return;
      }

      final double limit = (data['limit'] as num).toDouble();
      final bool useLimit = data['useLimit'] ?? false;
      if (useLimit && limit <= 0) {
        _showSnackBar("Coupon usage limit reached.", isError: true);
        return;
      }

      final double discountPercent = (data['discount'] as num).toDouble();
      double currentTotal = double.parse(widget.totalAmount);

      setState(() {
        _discountAmount = currentTotal * (discountPercent / 100);
        _appliedCouponId = doc.id;
        _isCouponApplied = true;
      });

      _showSnackBar("Coupon Applied: PKR ${_discountAmount.toStringAsFixed(0)} Off");
    } catch (e) {
      _showSnackBar("Error validating coupon.", isError: true);
    } finally {
      setState(() => _validatingCoupon = false);
    }
  }
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void getPaymentResponce() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      // 1. Pre-Payment Verification
      // We fetch a fresh snapshot of the coupon to ensure it wasn't disabled
      // or expired while the user was filling out the form.
      if (_isCouponApplied && _appliedCouponId != null) {
        DocumentSnapshot couponVerify = await FirebaseFirestore.instance
            .collection('coupons')
            .doc(_appliedCouponId)
            .get();



        bool isStillEnabled = couponVerify.get('isEnabled') ?? true;
        DateTime expireDate = (couponVerify.get('expireDate') as Timestamp).toDate();

        if (!isStillEnabled || DateTime.now().isAfter(expireDate)) {
          setState(() {
            _isCouponApplied = false;
            _discountAmount = 0.0;
          });
          _showSnackBar("Coupon is no longer valid. Please check your total.", isError: true);
          setState(() => loading = false);
          return; // Stop the payment process
        }
      }


      // 2. Process Payment
      double finalAmount = double.parse(widget.totalAmount) - _discountAmount;


      if (finalAmount < 170) { // Safety check for very small amounts
        _showSnackBar("Amount too small for card payment, Buy More Products.", isError: true);
        return;
      }

      bool flag = await StripeService.instance.makePayment(finalAmount.toInt());

      if (flag) {
        // 3. Post-Payment: Update Coupon Usage
        if (_isCouponApplied && _appliedCouponId != null) {
          DocumentReference couponRef = FirebaseFirestore.instance
              .collection('coupons')
              .doc(_appliedCouponId);


          DocumentSnapshot snap = await couponRef.get();
          bool useLimitActive = snap.get('useLimit') ?? false;

          if (useLimitActive) {
            // Decrease limit by 1.0 (double field in Firebase)
            await couponRef.update({
              'limit': FieldValue.increment(-1.0),
            });
          }

        }

        _showSnackBar("Payment Successful!");
        await _submitOrder(context);
      } else {
        _showSnackBar("Payment cancelled or failed.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double finalPayable = double.parse(widget.totalAmount) - _discountAmount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Shipping Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              _buildTextField(_nameController, _nameFocusNode, 'Full Name', Icons.person),
              const SizedBox(height: 15),
              _buildCityDropdown(),
              const SizedBox(height: 15),
              _buildTextField(_addressController, _addressFocusNode, 'Shipping Address', Icons.location_on),
              const SizedBox(height: 15),
              _buildTextField(_phoneController, _phoneFocusNode, 'Phone Number', Icons.phone, isNumber: true),
              const SizedBox(height: 15),
              _buildTextField(_postalCodeController, _postalCodeFocusNode, 'Postal Code', Icons.local_post_office, isNumber: true),

              const SizedBox(height: 30),
              const Text("Offers & Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // Coupon Field
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _couponController,
                      enabled: !_isCouponApplied,
                      decoration: InputDecoration(
                        hintText: 'Coupon Code',
                        prefixIcon: const Icon(Icons.confirmation_number_outlined, color: Colors.green),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _validatingCoupon
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _isCouponApplied ? null : _applyCoupon,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _isCouponApplied ? Colors.grey : Colors.green[800],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)
                    ),
                    child: Text(_isCouponApplied ? "Applied" : "Apply", style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Order Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _summaryRow("Subtotal", "PKR ${widget.totalAmount}"),
                    if (_isCouponApplied) ...[
                      const SizedBox(height: 10),
                      _summaryRow("Discount", "- PKR ${_discountAmount.toStringAsFixed(0)}", color: Colors.red),
                    ],
                    const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
                    _summaryRow("Total Payable", "PKR ${finalPayable.toStringAsFixed(0)}", isBold: true),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Main Buy Button
              ElevatedButton(
                onPressed: loading ? null : getPaymentResponce,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(width, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Confirm & Pay Now", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, FocusNode node, String label, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      focusNode: node,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: node.hasFocus ? Colors.green.withOpacity(0.05) : Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.green)),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildCityDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCity,
      decoration: InputDecoration(
        labelText: 'City',
        prefixIcon: const Icon(Icons.location_city, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      items: _cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
      onChanged: (value) => setState(() => _selectedCity = value),
      validator: (value) => value == null ? 'Please select a city' : null,
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? Colors.black87)),
      ],
    );
  }
/*
  void getPaymentResponce() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      double finalAmount = double.parse(widget.totalAmount) - _discountAmount;
      int totalIntAmount = finalAmount.toInt();

      bool flag = await StripeService.instance.makePayment(totalIntAmount);

      if (flag) {
        if (_isCouponApplied && _appliedCouponId != null) {
          await FirebaseFirestore.instance.collection('coupons').doc(_appliedCouponId).update({
            'usedCount': FieldValue.increment(1),
          });
        }
        _showSnackBar("Payment Successful!");
        await _submitOrder(context);
      } else {
        _showSnackBar("Payment Failed!", isError: true);
      }
    } catch (e) {
      _showSnackBar("Payment Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }*/

  Future<void> _submitOrder(BuildContext context) async {
    try {
      final ordersRef = FirebaseFirestore.instance.collection('orders');
      final userId = FirebaseAuth.instance.currentUser?.uid;

      for (var cartItem in widget.cartItems) {
        await decreaseProductQuantity(cartItem['productId'], cartItem['quantity']);

        final List<String> imageUrls = List<String>.from(cartItem['imageUrl'] ?? []);
        final orderId = ordersRef.doc().id;

        await ordersRef.doc(orderId).set({
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
          'totalPrice': (cartItem['price'] as double) * (cartItem['quantity'] as int).toDouble(),
          'orderDate': DateTime.now(),
          'timestamp': FieldValue.serverTimestamp(),
          'name': _nameController.text,
          'address': _addressController.text,
          'phoneNumber': _phoneController.text,
          'postalCode': _postalCodeController.text,
          'city': _selectedCity,
          'receiptImage': 'pending',
          'rated': false,
          'couponUsed': _isCouponApplied ? _appliedCouponId : null,
          'discountAmount': _isCouponApplied ? (_discountAmount / widget.cartItems.length) : 0,
        });
      }

      for (var cartItem in widget.cartItems) {
        await FirebaseFirestore.instance.collection('users').doc(userId).collection('addToCart').doc(cartItem.id).delete();
      }

      Navigator.pop(context);
    } catch (e) {
      _showSnackBar("Order Submission Failed", isError: true);
    }
  }

  Future<void> decreaseProductQuantity(String productId, int quantity) async {
    try {
      DocumentReference productRef = FirebaseFirestore.instance.collection('products').doc(productId);
      DocumentSnapshot snapshot = await productRef.get();
      if (snapshot.exists) {
        int currentQuantity = int.parse(snapshot['quantity'] ?? "0");
        if (currentQuantity >= quantity) {
          await productRef.update({'quantity': (currentQuantity - quantity).toString()});
        }
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
    }
  }
}