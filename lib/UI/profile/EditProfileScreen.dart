import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _selectedImage;
  String? profileImage;
  bool loading=false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;

    if (user != null) {
      loading=true;
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic>? userData =
        userDoc.data() as Map<String, dynamic>?;
        _fullNameController.text = userData?['name'] ?? '';
        _emailController.text = userData?['email'] ?? '';
        profileImage = userData?['profileImage'];
        setState(() {});
      }
      loading=false;
    } else {
      _showFloatingSnackBar('Failed to fetch user data', Colors.red);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      // Upload the image to Firebase Storage
      final storageRef =
      _storage.ref().child('profileImages/${user.uid}.jpg');
      await storageRef.putFile(imageFile);

      // Get the download URL
      return await storageRef.getDownloadURL();
    } catch (e) {
      _showFloatingSnackBar('Failed to upload image: $e', Colors.red);
      return null;
    }
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState?.validate() ?? false) {
      User? user = _auth.currentUser;
      loading=true;
      setState(() {

      });

      if (user != null) {
        try {
          String? imageUrl;
          if (_selectedImage != null) {
            // Upload the image to Firebase Storage and get the URL
            imageUrl = await _uploadImageToStorage(_selectedImage!);
          }

          // Update the user's data in Firestore
          await _firestore.collection('users').doc(user.uid).update({
            'name': _fullNameController.text,
            'email': _emailController.text,
            'profileImage': imageUrl ?? profileImage, // Update image if available
            'timestamp': FieldValue.serverTimestamp(),
          });
          loading=false;
          setState(() {

          });
          _showFloatingSnackBar('Profile updated successfully!', Colors.green);
        } catch (e) {
          _showFloatingSnackBar('Failed to save user data: $e', Colors.red);
        }
      }
    }
  }

  void _showFloatingSnackBar(String message, Color backgroundColor) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFullNameField() {
    return TextFormField(
      controller: _fullNameController,
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
        contentPadding:
        const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      enabled: false,
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: const Icon(Icons.email, color: Colors.grey),
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
        contentPadding:
        const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              GestureDetector(
                onTap: _showImagePickerDialog,
                child: Stack(
                  children: [
                    Positioned(
                      top: 80,
                      left: 200,
                      child: Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(Icons.edit),
                      ),
                    ),
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (profileImage != null
                          ? NetworkImage(profileImage!)
                          : const AssetImage('assets/img_2.png')
                      as ImageProvider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFullNameField(),
              const SizedBox(height: 16),
              _buildEmailField(),
              const SizedBox(height: 16),
              loading == false
                  ? ElevatedButton(
                onPressed: _saveUserData,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(width, 50), // Set width and height
                  backgroundColor: Colors.green, // Set button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25), // Rounded corners
                  ),
                ),
                child: const Text(
                  "Update",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              )
                  : const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
