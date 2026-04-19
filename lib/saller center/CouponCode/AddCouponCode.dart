import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddCouponScreen extends StatefulWidget {
  const AddCouponScreen({super.key});

  @override
  State<AddCouponScreen> createState() => _AddCouponScreenState();
}

class _AddCouponScreenState extends State<AddCouponScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  final _limitController = TextEditingController();

  DateTime? _selectedDate;
  bool _useLimit = true;
  bool _isEnabled = true; // New variable for toggle
  bool _isLoading = false;

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveCoupon() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and pick an expiry date")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sellerId = FirebaseAuth.instance.currentUser?.uid;
      String storeName = "Unknown Store"; // Default fallback

      // 1. Fetch the store name from the 'saller' collection
      if (sellerId != null) {
        DocumentSnapshot sellerDoc = await FirebaseFirestore.instance
            .collection('saller')
            .doc(sellerId)
            .get();

        if (sellerDoc.exists) {
          // Change 'storeName' to whatever your field name is in the saller collection
          storeName = sellerDoc.get('storeName') ?? "Unknown Store";
        }
      }

      // 2. Add the coupon with the fetched store name
      await FirebaseFirestore.instance.collection('coupons').add({
        'couponCode': _codeController.text.trim().toUpperCase(),
        'title': "$storeName Special", // We save it as the title for the banner
        'storeName': storeName,        // Explicit field for easier display later
        'discount': double.parse(_discountController.text),
        'expireDate': Timestamp.fromDate(_selectedDate!),
        'limit': _useLimit ? double.parse(_limitController.text) : 0.0,
        'useLimit': _useLimit,
        'isEnabled': _isEnabled,
        'sellerId': sellerId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Coupon created successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Coupon"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Coupon Code (Customer will enter this)"),
              _buildTextField(_codeController, "e.g. ZRAI20", Icons.abc),

              const SizedBox(height: 20),
              _buildLabel("Discount Percentage (%)"),
              _buildTextField(_discountController, "e.g. 10", Icons.percent, isNumber: true),

              const SizedBox(height: 20),
              _buildLabel("Expiry Date"),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? "Select Date"
                            : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_month, color: Colors.green),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- ENABLE/DISABLE TOGGLE ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Enable Coupon", style: TextStyle(fontWeight: FontWeight.bold)),
                  Switch(
                    value: _isEnabled,
                    activeColor: Colors.green,
                    onChanged: (v) => setState(() => _isEnabled = v),
                  ),
                ],
              ),
              const Divider(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Enable Usage Limit", style: TextStyle(fontWeight: FontWeight.bold)),
                  Switch(
                    value: _useLimit,
                    activeColor: Colors.green,
                    onChanged: (v) => setState(() => _useLimit = v),
                  ),
                ],
              ),

              if (_useLimit) ...[
                const SizedBox(height: 10),
                _buildLabel("Usage Limit (Max users)"),
                _buildTextField(_limitController, "e.g. 10", Icons.people, isNumber: true),
              ],

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCoupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Coupon", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (v) => v == null || v.isEmpty ? "Field required" : null,
    );
  }
}