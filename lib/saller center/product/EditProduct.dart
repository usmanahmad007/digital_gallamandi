import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProduct extends StatefulWidget {
  final String productId;

  const EditProduct({required this.productId, super.key});

  @override
  State<EditProduct> createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  final picker = ImagePicker();
  bool _isUploading = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();
  final FocusNode _quantityFocusNode = FocusNode();

  String? _selectedCategory;
  bool isRental = false; // Linked to the UI toggle

  List<DropdownMenuItem<String>> _categoryDropdownItems = [];
  List<String> _imageUrls = [];
  final List<File> _newImages = [];

  @override
  void initState() {
    super.initState();
    _loadProductData();
    _loadCategories();
  }

  Future<void> _loadProductData() async {
    setState(() => _isUploading = true);
    DocumentSnapshot productDoc = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .get();

    if (productDoc.exists) {
      Map<String, dynamic> productData = productDoc.data() as Map<String, dynamic>;
      _titleController.text = productData['title'] ?? '';
      _descriptionController.text = productData['description'] ?? '';
      _priceController.text = productData['price'] ?? '';
      _selectedCategory = productData['category'];
      _quantityController.text = productData['quantity'] ?? '';
      isRental = productData['isRental'] ?? false;
      if (productData['imageUrls'] != null) {
        _imageUrls = List<String>.from(productData['imageUrls']);
      }
    }
    setState(() => _isUploading = false);
  }

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('category').get();
    setState(() {
      _categoryDropdownItems = snapshot.docs.map((doc) {
        final categoryName = doc['category'];
        return DropdownMenuItem<String>(
          value: categoryName,
          child: Text(categoryName),
        );
      }).toList();
    });
  }

  Future<void> _pickImage() async {
    if (_imageUrls.length + _newImages.length >= 3) {
      _showSnackbar('Maximum 3 images allowed', Colors.red);
      return;
    }
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _newImages.add(File(pickedFile.path)));
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference firebaseStorageRef = FirebaseStorage.instance.ref().child('productImages/$fileName');
      UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  void _editProduct() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar('Please fill all the fields correctly', Colors.red);
      return;
    }
    if (_imageUrls.isEmpty && _newImages.isEmpty) {
      _showSnackbar('At least 1 image is required', Colors.red);
      return;
    }

    setState(() => _isUploading = true);
    try {
      List<String> allImageUrls = [..._imageUrls];
      for (File image in _newImages) {
        String? imageUrl = await _uploadImageToFirebase(image);
        if (imageUrl != null) allImageUrls.add(imageUrl);
      }

      await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': _priceController.text,
        'imageUrls': allImageUrls,
        'category': isRental ? "Rental" : _selectedCategory,
        'isRental': isRental,
        'quantity': isRental ? "0" : _quantityController.text,
      });

      _showSnackbar('Product updated successfully', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      _showSnackbar('Update Failed: $e', Colors.red);
    }
    setState(() => _isUploading = false);
  }

  void _removeImage(int index, bool isNewImage) {
    setState(() {
      if (isNewImage) {
        _newImages.removeAt(index);
      } else {
        _imageUrls.removeAt(index);
      }
    });
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Product Images", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Icon(Icons.add_a_photo, color: Colors.green),
                ),
              ),
              const SizedBox(width: 10),
              ...List.generate(_imageUrls.length, (i) => _imageCard(_imageUrls[i], i, false)),
              ...List.generate(_newImages.length, (i) => _imageCard(_newImages[i], i, true)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageCard(dynamic src, int index, bool isFile) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 10),
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(
              image: isFile ? FileImage(src) : NetworkImage(src) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 5,
          child: IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () => _removeImage(index, isFile),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.green, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Edit Product', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isUploading && _titleController.text.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImageSection(),
              const SizedBox(height: 25),

              // RENTAL TOGGLE CARD
              Container(
                decoration: BoxDecoration(
                  color: isRental ? Colors.green.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isRental ? Colors.green : Colors.transparent),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                ),
                child: CheckboxListTile(
                  value: isRental,
                  activeColor: Colors.green,
                  title: const Text("List as Rental Item?", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Tractors, Tools, or Machinery"),
                  onChanged: (val) => setState(() => isRental = val ?? false),
                ),
              ),

              const SizedBox(height: 25),

              // INPUT CONTAINER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      decoration: _inputStyle("Product Title", Icons.title),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _descriptionController,
                      focusNode: _descriptionFocusNode,
                      maxLines: 3,
                      decoration: _inputStyle("Description", Icons.description),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _priceController,
                      focusNode: _priceFocusNode,
                      keyboardType: TextInputType.number,
                      decoration: _inputStyle(isRental ? "Rent /hr (PKR)" : "Price (PKR)", Icons.payments_outlined),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),

                    // Hide Quantity if Rental
                    if (!isRental) ...[
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _quantityController,
                        focusNode: _quantityFocusNode,
                        keyboardType: TextInputType.number,
                        decoration: _inputStyle("Total Kg / Quantity", Icons.inventory_2_outlined),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ],

                    // Hide Category if Rental (Add Product Logic)
                    // Hide Category if Rental (Add Product Logic)
                    if (!isRental) ...[
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        // FIX: Check if _selectedCategory exists in the dropdown items.
                        // If not, set it to null so the dropdown doesn't crash.
                        value: _categoryDropdownItems.any((item) => item.value == _selectedCategory)
                            ? _selectedCategory
                            : null,
                        decoration: _inputStyle("Category", Icons.category_outlined),
                        items: _categoryDropdownItems,
                        onChanged: (v) => setState(() => _selectedCategory = v),
                        validator: (v) => (v == null && !isRental) ? 'Required' : null,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),

              _isUploading
                  ? const CircularProgressIndicator(color: Colors.green)
                  : SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _editProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    shadowColor: Colors.green.withOpacity(0.4),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}