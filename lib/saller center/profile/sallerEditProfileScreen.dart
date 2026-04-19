import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../app_colors.dart';
// import 'package:zrai_mart/utils/app_colors.dart';

class sallerEditProfileScreen extends StatefulWidget {
  const sallerEditProfileScreen({super.key});

  @override
  _sallerEditProfileScreenState createState() => _sallerEditProfileScreenState();
}

class _sallerEditProfileScreenState extends State<sallerEditProfileScreen> {
  // --- BACKEND LOGIC & CONTROLLERS (UNTOUCHED) ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _selectedImage;
  String? profileImage;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- DATA LOADING & IMAGE PICKING (UNTOUCHED) ---
  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() => loading = true);
      DocumentSnapshot userDoc = await _firestore.collection('saller').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        _fullNameController.text = userData?['name'] ?? '';
        _emailController.text = userData?['email'] ?? '';
        profileImage = userData?['profileImage'];
      }
      setState(() => loading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;
      final storageRef = _storage.ref().child('profileImages/${user.uid}.jpg');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      _showFloatingSnackBar('Failed to upload image: $e', AppColors.errorRed);
      return null;
    }
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState?.validate() ?? false) {
      User? user = _auth.currentUser;
      if (user != null) {
        setState(() => loading = true);
        try {
          String? imageUrl;
          if (_selectedImage != null) {
            imageUrl = await _uploadImageToStorage(_selectedImage!);
          }
          await _firestore.collection('saller').doc(user.uid).update({
            'name': _fullNameController.text,
            'email': _emailController.text,
            'profileImage': imageUrl ?? profileImage,
            'type': "saller",
            'timestamp': FieldValue.serverTimestamp(),
          });
          _showFloatingSnackBar('Profile updated successfully!', AppColors.successGreen);
        } catch (e) {
          _showFloatingSnackBar('Failed to update: $e', AppColors.errorRed);
        }
        setState(() => loading = false);
      }
    }
  }

  void _showFloatingSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Change Profile Photo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primaryGreen),
              title: const Text('Take Photo'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primaryGreen),
              title: const Text('Choose from Gallery'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading && _fullNameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- PROFILE IMAGE SECTION ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (profileImage != null
                            ? NetworkImage(profileImage!)
                            : const AssetImage('assets/img_2.png') as ImageProvider),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImagePickerDialog,
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primaryGreen,
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- INPUT FIELDS ---
              _buildModernField(
                controller: _fullNameController,
                label: "Full Name",
                icon: Icons.person_outline,
                focusNode: _nameFocusNode,
              ),
              const SizedBox(height: 20),
              _buildModernField(
                controller: _emailController,
                label: "Email Address",
                icon: Icons.email_outlined,
                enabled: false, // Email is typically fixed
              ),

              const SizedBox(height: 40),

              // --- UPDATE BUTTON ---
              loading
                  ? const CircularProgressIndicator(color: AppColors.primaryGreen)
                  : SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? AppColors.cardWhite : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        boxShadow: enabled ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        style: TextStyle(color: enabled ? AppColors.textDark : AppColors.textGrey),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.primaryGreen),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'This field is required' : null,
      ),
    );
  }
}