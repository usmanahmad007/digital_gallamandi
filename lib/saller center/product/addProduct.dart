import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Addproduct extends StatefulWidget {
  const Addproduct({Key? key}) : super(key: key);

  @override
  _AddproductState createState() => _AddproductState();
}

class _AddproductState extends State<Addproduct> {
  String fileName = DateTime.now().millisecondsSinceEpoch.toString();
  File? _image;
  final picker = ImagePicker();
  bool _isUploading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();

  // New fields
  String? _selectedCategory;
  List<DropdownMenuItem<String>> _categoryDropdownItems = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('category').get();
    final List<DropdownMenuItem<String>> items = snapshot.docs
        .map((doc) {
      final categoryName = doc['category'];
      return DropdownMenuItem<String>(
        value: categoryName,
        child: Text(categoryName),
      );
    })
        .toList();
    setState(() {
      _categoryDropdownItems = items;
    });
  }

  Future<void> getImage(bool isCamera) async {
    final pickedFile = await picker.pickImage(
      source: isCamera ? ImageSource.camera : ImageSource.gallery,
    );

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<String?> uploadImageToFirebase(File imageFile) async {
    Reference firebaseStorageRef = FirebaseStorage.instance.ref().child('productImages/$fileName');
    print("GIFT6");


    try {
      print("GIFT8");

      UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _uploadProduct() async {
    if (_image == null) {
      _showSnackbar('Please select an image first', Colors.red);
      return;
    }
    print("GIFT1");

    if (_selectedCategory == null) {
      _showSnackbar('Please select a category', Colors.red);
      return;
    }
    print("GIFT2");

    if (!_formKey.currentState!.validate()) {
      _showSnackbar('Please fill all the fields correctly', Colors.red);
      return;
    }
    print("GIFT3");

    setState(() {
      _isUploading = true;
    });
    print("GIFT33");


    String? imageUrl = await uploadImageToFirebase(_image!);
    print("GIFT4");

    setState(() {
      _isUploading = false;
    });
    print("GIFT5");

    if (imageUrl != null) {
      print("GIFT6");

      _showSnackbar('Product uploaded successfully', Colors.green);

      // Upload product data to Firestore
      FirebaseFirestore.instance.collection('products').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': _priceController.text,
        'imageUrl': imageUrl,
        'sellerId': FirebaseAuth.instance.currentUser?.uid,
        'productId': fileName,
        'category': _selectedCategory, // Store the selected category name
        'buyUID': '',
      });
      Navigator.pop(context);
    } else {
      _showSnackbar('Product upload failed', Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: _selectedCategory != null ? Colors.greenAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(25),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(25),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      value: _selectedCategory,
      items: _categoryDropdownItems,
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
          print(_selectedCategory);
        });
      },
      dropdownColor: Colors.white, // Background color of the dropdown menu
      style: TextStyle(color: Colors.black), // Text color of the selected item
      iconEnabledColor: Colors.green, // Color of the dropdown arrow
      validator: (value) {
        if (value == null) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      focusNode: _titleFocusNode,
      decoration: InputDecoration(
        labelText: 'Title',
        prefixIcon: Icon(Icons.title, color: Colors.grey),
        labelStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: _titleFocusNode.hasFocus ? Colors.greenAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(25),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(25),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the product title';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      focusNode: _descriptionFocusNode,
      decoration: InputDecoration(
        labelText: 'Description',
        prefixIcon: Icon(Icons.description, color: Colors.grey),
        labelStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: _descriptionFocusNode.hasFocus ? Colors.greenAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(25),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(25),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the product description';
        }
        return null;
      },
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      focusNode: _priceFocusNode,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Price',
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            "PKR",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        labelStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: _priceFocusNode.hasFocus ? Colors.greenAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(25),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(25),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the product price';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _pickImage,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _image == null
                    ? GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: width / 8,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        width: 150,
                        height: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add),
                            Text(
                              "Add Image",
                              style: TextStyle(color: Colors.black),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                    : Container(
                  width: width / 0.4,
                  height: 200,
                  child: Image.file(
                    _image!,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTitleField(),
                const SizedBox(height: 16),
                _buildDescriptionField(),
                const SizedBox(height: 16),
                _buildPriceField(),
                const SizedBox(height: 16),
                _buildDropdownField(), // Updated Dropdown Field
                const SizedBox(height: 16),
                _isUploading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: _uploadProduct,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Text(
                        'Add Product',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickImage() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  getImage(false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  getImage(true);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
