import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UploadBlogPostScreen extends StatefulWidget {
  const UploadBlogPostScreen({super.key});

  @override
  _UploadBlogPostScreenState createState() => _UploadBlogPostScreenState();
}

class _UploadBlogPostScreenState extends State<UploadBlogPostScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _image;
  bool _isUploading = false;

  // Pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImage(File image) async {
    try {
      // Create a unique file name
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload image to Firebase Storage
      TaskSnapshot snapshot = await _storage.ref().child('blog_images/$fileName').putFile(image);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Save blog post data to Firestore
  Future<void> _saveBlogPost() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields are required')));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    // Upload image and get the URL
    String? imageUrl = await _uploadImage(_image!);

    if (imageUrl != null) {
      try {
        // Add blog post to Firestore
        await _firestore.collection('blogs').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'imageUrl': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Blog posted successfully!')));

        // Clear form after submission
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _image = null;
        });
      } catch (e) {
        print('Error saving blog post: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error posting blog')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
    }

    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width=MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Blog Post'),
        backgroundColor: Colors.green, // Green AppBar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Title field
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.green), // Green label
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Description field
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.green), // Green label
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              // Image preview
              _image == null
                  ? const Text('No image selected.', style: TextStyle(color: Colors.grey))
                  : Image.file(_image!, height: 200, width: double.infinity, fit: BoxFit.cover),
              const SizedBox(height: 16),
              // Pick Image button
              SizedBox(
                width: width*0.9,
                child: ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.green, // White text
                  ),
                  child: const Text('Pick Image',style: TextStyle(color: Colors.black),),
                ),
              ),
              const SizedBox(height: 16),
              // Submit Blog button
              _isUploading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: width*0.9,
                    child: ElevatedButton(
                                  onPressed: _saveBlogPost,
                                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.green, // White text
                                  ),
                                  child: const Text('Post Blog',style: TextStyle(color: Colors.black),),
                                ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
