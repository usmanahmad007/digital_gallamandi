import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UpdateBlogScreen extends StatefulWidget {
  final String blogId;
  final String currentTitle;
  final String currentDescription;
  final String currentImageUrl;

  const UpdateBlogScreen({super.key, 
    required this.blogId,
    required this.currentTitle,
    required this.currentDescription,
    required this.currentImageUrl,
  });

  @override
  _UpdateBlogScreenState createState() => _UpdateBlogScreenState();
}

class _UpdateBlogScreenState extends State<UpdateBlogScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _newImage;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.currentTitle;
    _descriptionController.text = widget.currentDescription;
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _newImage = File(pickedFile.path);
      });
    }
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImage(File image) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      TaskSnapshot snapshot = await _storage.ref().child('blog_images/$fileName').putFile(image);
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Update blog post data in Firestore
  Future<void> _updateBlog() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields are required')));
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    String? imageUrl = widget.currentImageUrl;
    if (_newImage != null) {
      imageUrl = await _uploadImage(_newImage!);
    }

    try {
      await _firestore.collection('blogs').doc(widget.blogId).update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': imageUrl ?? widget.currentImageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Blog updated successfully')));
      Navigator.pop(context);
    } catch (e) {
      print('Error updating blog: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating blog')));
    }

    setState(() {
      _isUpdating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Blog'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            // Description field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 8),
            // Image preview or selection
            _newImage == null
                ? (widget.currentImageUrl.isEmpty
                ? const Text('No image selected.')
                : Image.network(widget.currentImageUrl, height: 100))
                : Image.file(_newImage!, height: 100),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Green color for the button
              ),
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 16),
            // Update blog button
            _isUpdating
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _updateBlog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Green color for the button
              ),
              child: const Text('Update Blog'),
            ),
          ],
        ),
      ),
    );
  }
}
