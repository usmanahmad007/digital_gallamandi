import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_colors.dart';
// import 'package:zrai_mart/utils/app_colors.dart';

class Addproduct extends StatefulWidget {
  const Addproduct({super.key});

  @override
  _AddproductState createState() => _AddproductState();
}

class _AddproductState extends State<Addproduct> {
  // --- LOGIC & CONTROLLERS (PRESERVED) ---
  final picker = ImagePicker();
  bool _isUploading = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  final List<File> _images = [];
  String? _selectedCategory;
  List<DropdownMenuItem<String>> _categoryDropdownItems = [];
  bool _isRental = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // --- FIREBASE LOGIC (UNTOUCHED) ---
  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('category').get();
    setState(() {
      _categoryDropdownItems = snapshot.docs.map((doc) {
        return DropdownMenuItem<String>(value: doc['category'], child: Text(doc['category']));
      }).toList();
    });
  }

  Future<void> getImage(bool isCamera) async {
    if (_images.length >= 3) {
      _showSnackbar('Limit: 3 images max', AppColors.errorRed);
      return;
    }
    final pickedFile = await picker.pickImage(source: isCamera ? ImageSource.camera : ImageSource.gallery);
    if (pickedFile != null) setState(() => _images.add(File(pickedFile.path)));
  }

  Future<void> _uploadProduct() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      // 1. Fetch Seller Status
      DocumentSnapshot sellerDoc = await FirebaseFirestore.instance
          .collection('saller')
          .doc(user.uid)
          .get();

      if (!sellerDoc.exists) {
        _showErrorDialog("Account Not Found", "Please complete your registration.");
        setState(() => _isUploading = false);
        return;
      }

      var data = sellerDoc.data() as Map<String, dynamic>;
      bool hasSetup = data['hasSetupStore'] ?? false;
      bool isApproved = data['isAdminApproved'] ?? false;
      bool isRestricted = data['isSellerRestricted'] ?? false;

      // 2. Check Conditions
      if (!hasSetup) {
        _showErrorDialog("Setup Incomplete", "Please finish setting up your store profile before adding products.");
      } else if (!isApproved) {
        _showErrorDialog("Pending Approval", "Your store is currently under review by our team. You can add products once approved.");
      } else if (isRestricted) {
        _showErrorDialog("Account Restricted", "Your seller account has been restricted. Please contact support for more information.");
      } else {
        // 3. Proceed with existing Upload Logic if all conditions pass
        if (_images.isEmpty) {
          _showSnackbar('Add at least 1 image', AppColors.errorRed);
          setState(() => _isUploading = false);
          return;
        }
        if (!_formKey.currentState!.validate()) {
          setState(() => _isUploading = false);
          return;
        }

        List<String> imageUrls = [];
        for (var img in _images) {
          String name = DateTime.now().millisecondsSinceEpoch.toString();
          var ref = FirebaseStorage.instance.ref().child('productImages/$name');
          await ref.putFile(img);
          imageUrls.add(await ref.getDownloadURL());
        }

        await FirebaseFirestore.instance.collection('products').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'price': _priceController.text,
          'imageUrls': imageUrls,
          'sellerId': user.uid,
          'productId': DateTime.now().millisecondsSinceEpoch.toString(),
          'category': _isRental ? "Rental" : _selectedCategory,
          'isRental': _isRental,
          'quantity': _isRental ? "0" : _quantityController.text,
          'rating': ['0.0'],
          'averageRating': '0.0'
        });

        _showSnackbar('Product Listed Successfully!', AppColors.successGreen);
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackbar('Upload Failed: $e', AppColors.errorRed);
    }

    if (mounted) setState(() => _isUploading = false);
  }

// Helper to show the status dialogs
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('List New Item', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Modern Image Selector
              const Text("Product Images (Max 3)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildModernImagePicker(),

              const SizedBox(height: 25),

              // 2. Rental Toggle Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isRental ? AppColors.primaryGreen.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _isRental ? AppColors.primaryGreen : Colors.transparent),
                ),
                child: CheckboxListTile(
                  value: _isRental,
                  activeColor: AppColors.primaryGreen,
                  title: const Text("List as Rental Item?", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Tractors, Tools, or Machinery"),
                  onChanged: (val) => setState(() => _isRental = val ?? false),
                ),
              ),

              const SizedBox(height: 25),

              // 3. Form Fields
              _buildInputLabel("Basic Details"),
              _buildTextField(_titleController, "Item Title (e.g. Basmati Rice)", Icons.title),
              const SizedBox(height: 15),
              _buildTextField(_descriptionController, "Detailed Description", Icons.description, maxLines: 3),

              const SizedBox(height: 25),
              _buildInputLabel("Pricing & Inventory"),
              Row(
                children: [
                  Expanded(child: _buildTextField(_priceController, _isRental ? "Rent /hr" : "Price", Icons.payments_outlined, isNumber: true)),
                  if (!_isRental) const SizedBox(width: 15),
                  if (!_isRental) Expanded(child: _buildTextField(_quantityController, "Total Kg", Icons.inventory_2_outlined, isNumber: true)),
                ],
              ),

              const SizedBox(height: 15),
              if (!_isRental) ...[
                _buildInputLabel("Category"),
                _buildDropdownField(),
              ],

              const SizedBox(height: 40),

              // 4. Submit Button
              _isUploading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                  : SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _uploadProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text("Confirm & List Item", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernImagePicker() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index < _images.length) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_images[index], width: 100, height: 100, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 5, right: 5,
                  child: GestureDetector(
                    onTap: () => setState(() => _images.removeAt(index)),
                    child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)),
                  ),
                ),
              ],
            );
          }
          return GestureDetector(
            onTap: () => _pickImageSource(),
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: const Icon(Icons.add_a_photo_outlined, color: AppColors.textGrey),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1, bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryGreen),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(border: InputBorder.none),
        hint: const Text("Select Category"),
        value: _selectedCategory,
        items: _categoryDropdownItems,
        onChanged: (val) => setState(() => _selectedCategory = val),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGrey, fontSize: 13)),
    );
  }

  void _pickImageSource() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () { Navigator.pop(context); getImage(true); }),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { Navigator.pop(context); getImage(false); }),
          ],
        ),
      ),
    );
  }
}