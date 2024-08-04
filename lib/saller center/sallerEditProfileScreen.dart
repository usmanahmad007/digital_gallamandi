import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class sallerEditProfileScreen extends StatefulWidget {
  @override
  _sallerEditProfileScreenState createState() => _sallerEditProfileScreenState();
}

class _sallerEditProfileScreenState extends State<sallerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    print("gift");
    if (user != null) {
      print("gift1");

      DocumentSnapshot userDoc = await _firestore.collection('saller').doc(user.uid).get();
      print("gift2");

      if (userDoc.exists) {
        print("gift3");

        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        _fullNameController.text = userData?['name'] ?? '';
        _emailController.text = userData?['email'] ?? '';
      }
    }

  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState?.validate() ?? false) {
      User? user = _auth.currentUser;

      if (user != null) {
        try {
          await _firestore.collection('saller').doc(user.uid).update({
            'name': _fullNameController.text,
            'email': _emailController.text,
            'type': "saller",
            'timestamp': FieldValue.serverTimestamp(),
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
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _buildFullNameField() {
    return TextFormField(
      controller: _fullNameController,
      focusNode: _nameFocusNode,
      decoration: InputDecoration(
        labelText: 'Full Name',
        prefixIcon: Icon(Icons.person, color: Colors.grey),
        labelStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: _nameFocusNode.hasFocus ? Colors.greenAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
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
        prefixIcon: Icon(Icons.email, color: Colors.grey),
        labelStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.1),
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
          return 'Please enter your email';
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
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              _buildFullNameField(),
              SizedBox(height: 16),
              _buildEmailField(),
              SizedBox(height: 16),
              GestureDetector(
                onTap: _saveUserData,
                child: Center(
                  child: Container(
                    width: width/1,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        "update",style: TextStyle(color: Colors.white,),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
