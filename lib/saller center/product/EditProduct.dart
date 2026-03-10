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
  File? _image;
  String? _imageUrl;
  String? _selectedCategory;
  final picker = ImagePicker();
  bool _isUploading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _quantityFocusNode = FocusNode();
  bool isRental=false;

  List<DropdownMenuItem<String>> _categoryDropdownItems = [];
  List<String> _imageUrls = []; // List to hold existing Firebase image URLs
  final List<File> _newImages = []; // List to hold newly added images


  @override
  void initState() {
    super.initState();
    _loadProductData();
    _loadCategories();
  }

  Future<void> _loadProductData() async {
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
      _quantityController.text=productData['quantity']?? '';
      isRental=productData['isRental']?? false;
      if (productData['imageUrls'] != null) {
        _imageUrls = List<String>.from(productData['imageUrls']);
      }
      setState(() {});
    }
  }

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('category').get();
    setState(() {
      _categoryDropdownItems = snapshot.docs
          .map((doc) {
        final categoryName = doc['category'];
        return DropdownMenuItem<String>(
          value: categoryName,
          child: Text(categoryName),
        );
      })
          .toList();
    });
  }

  Future<void> _pickImage() async {
    if (_imageUrls.length + _newImages.length >= 3) {
      _showSnackbar('Maximum 3 images allowed', Colors.red);
      return;
    }

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newImages.add(File(pickedFile.path));
      });
    } else {
      print('No image selected.');
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference firebaseStorageRef =
      FirebaseStorage.instance.ref().child('productImages/$fileName');
      UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
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

    setState(() {
      _isUploading = true;
    });

    List<String> allImageUrls = [..._imageUrls];

    for (File image in _newImages) {
      String? imageUrl = await _uploadImageToFirebase(image);
      if (imageUrl != null) {
        allImageUrls.add(imageUrl);
      }
    }

    await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'price': _priceController.text,
      'imageUrls': allImageUrls,
      'category': _selectedCategory,
      'quantity': _quantityController.text,
    });

    setState(() {
      _isUploading = false;
    });

    _showSnackbar('Product updated successfully', Colors.green);
    Navigator.pop(context);
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
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Widget _buildImageList() {
    List<Widget> imageWidgets = [];

    for (int i = 0; i < _imageUrls.length; i++) {
      imageWidgets.add(Stack(
        children: [
          Image.network(_imageUrls[i], width: 100, height: 100, fit: BoxFit.cover),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _removeImage(i, false),
            ),
          ),
        ],
      ));
    }

    for (int i = 0; i < _newImages.length; i++) {
      imageWidgets.add(Stack(
        children: [
          Image.file(_newImages[i], width: 100, height: 100, fit: BoxFit.cover),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _removeImage(i, true),
            ),
          ),
        ],
      ));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: imageWidgets,
    );
  }

/*
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

  void _editProduct() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar('Please fill all the fields correctly', Colors.red);
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String? imageUrl = _imageUrl;
    if (_image != null) {
      imageUrl = await uploadImageToFirebase(_image!);
    }

    setState(() {
      _isUploading = false;
    });

    if (imageUrl != null) {
      FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': _priceController.text,
        'imageUrl': imageUrl,
        'category': _selectedCategory,
      });

      _showSnackbar('Product updated successfully', Colors.green);
      Navigator.pop(context);
    } else {
      _showSnackbar('Product update failed', Colors.red);
    }
  }*/

  /*void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }*/
  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      focusNode: _quantityFocusNode,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Quantity',
        prefixIcon: const Icon(Icons.production_quantity_limits, color: Colors.grey),
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: _quantityFocusNode.hasFocus
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
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the quantity';
        }
        if (int.tryParse(value) == null || int.parse(value) <= 0) {
          return 'Please enter a valid quantity';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField() {
    if (_selectedCategory == 'Rental') {
      // If category is "Rental", don't show the dropdown
      return Container();
    } else {
      // Otherwise, show the dropdown
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Category',
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: _selectedCategory != null ? Colors.greenAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(25),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.green),
            borderRadius: BorderRadius.circular(25),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        initialValue: _selectedCategory,
        items: _categoryDropdownItems,
        onChanged: (value) {
          setState(() {
            _selectedCategory = value;
          });
        },
        dropdownColor: Colors.white,
        style: const TextStyle(color: Colors.black),
        iconEnabledColor: Colors.green,
        validator: (value) {
          if (value == null) {
            return 'Please select a category';
          }
          return null;
        },
      );
    }
  }


  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      focusNode: _titleFocusNode,
      decoration: InputDecoration(
        labelText: 'Title',
        prefixIcon: const Icon(Icons.title, color: Colors.grey),
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: _titleFocusNode.hasFocus ? Colors.greenAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(25),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(25),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
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
        prefixIcon: const Icon(Icons.description, color: Colors.grey),
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: _descriptionFocusNode.hasFocus ? Colors.greenAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(25),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(25),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
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
        prefixIcon: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              "PKR",style: TextStyle(
                color: Colors.grey,fontSize: 18
            ),
            )),
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: _priceFocusNode.hasFocus ? Colors.greenAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(25),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(25),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
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
    final width=MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /*_image == null && _imageUrl == null
                  ? GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: width / 8,
                  height: 200,
                  decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(25)),
                      width: 150,
                      height: 50,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                  : _image != null
                  ? GestureDetector(
                onTap: _pickImage,
                    child: SizedBox(
                                    width: width / 0.4,
                                    height: 200,
                                    child: Image.file(
                    _image!,
                    fit: BoxFit.cover,
                                    ),
                                  ),
                  )
                  : GestureDetector(
                onTap: _pickImage,
                    child: SizedBox(
                                    width: width / 0.4,
                                    height: 200,
                                    child: Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover,
                                    ),
                                  ),
                  ),*/
              _buildImageList(),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTitleField(),
                    const SizedBox(height: 10),
                    _buildDescriptionField(),
                    const SizedBox(height: 10),
                    _buildPriceField(),
                    const SizedBox(height: 10),
                    isRental==false?
                    _buildQuantityField():Container(),
                    const SizedBox(height: 10),
                    _buildDropdownField(),
                    const SizedBox(height: 20),
                    _isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : Container(
                      width: width/0.9,
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
                        onPressed: _editProduct,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Text(
                            'Update',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
