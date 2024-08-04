import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zrai_mart/UI/ForgotPasswordScreen.dart';
import 'package:zrai_mart/UI/SignupScreen.dart';
import 'package:zrai_mart/UI/bottomTabs.dart';

import '../saller center/sallerbottomTabs.dart';
import 'EmailVerificationScreen.dart';

class Signinscreen extends StatefulWidget {
  const Signinscreen({super.key});

  @override
  State<Signinscreen> createState() => _SigninscreenState();
}

class _SigninscreenState extends State<Signinscreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final _firebaseAuth=FirebaseAuth.instance;
  bool _isPasswordVisible = false;
  bool _isAcceptedTerms = false;
  bool _isChecked = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }
  void _showFloatingSnackBar(String message, Color backgroundColor) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.fixed,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
  Future<void> _signIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        User? user = userCredential.user;

        if (user != null) {
          if (!user.emailVerified) {
            // Navigate to email verification screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => EmailVerificationScreen()),
            );
            return;
          }

          DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
          DocumentSnapshot sallerDoc = await _firestore.collection('saller').doc(user.uid).get();

          if (userDoc.exists) {
            Fluttertoast.showToast( msg: 'sign-in successful!');

          //  _showFloatingSnackBar('Sign-in successful!', Colors.green);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => BottomTabs()),
                  (Route<dynamic> route) => false,
            );
          } else if (sallerDoc.exists) {
            Fluttertoast.showToast( msg: 'sign-in successful!');

            // _showFloatingSnackBar('Sign-in successful!', Colors.green);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => sallerBottomTabs()),
                  (Route<dynamic> route) => false,
            );
          } else {
            Fluttertoast.showToast( msg: 'User not found');

          //  _showFloatingSnackBar('User not found.', Colors.red);
          }
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided.';
        } else {
          message = 'Sign-in failed. ${e.message}';
        }
        Fluttertoast.showToast(msg: message);
        //_showFloatingSnackBar(message, Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height=MediaQuery.of(context).size.height;
    final width=MediaQuery.of(context).size.width;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 50,),
                  Image.asset("assets/img_1.png",width: 250,height: 250,),
                  Text("Login",style: TextStyle(
                      fontSize: 24,fontWeight: FontWeight.bold
                  )
                  ),
                  SizedBox(height: 20),

                  _buildEmailField(),
                  SizedBox(height: 20),
                  _buildPasswordField(),
                  SizedBox(height: 10),
               //   _buildTermsAndConditions(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Checkbox(
                            value: _isChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                _isChecked = value ?? false;
                              });
                            },
                          ),
                          Text('Sign In as saller'),
                        ],
                      ),
                      GestureDetector(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>ForgotPasswordScreen()));
                        },
                        child: Text("Forgot Password?"),
                      )
                    ],
                  ),
                  SizedBox(height: 10),


                  GestureDetector(
                    onTap: _signIn,
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
                            "Sign In",style: TextStyle(color: Colors.white,),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 70,),
                  Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("don't have an account?"),
                      InkWell(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>Signupscreen()));

                        },
                          child: Text("SignUp",style: TextStyle(color: Colors.green),))
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email, color: Colors.grey),
        labelStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: _emailFocusNode.hasFocus ? Colors.greenAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
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
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.grey),
        prefixIcon: Icon(Icons.lock, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: _togglePasswordVisibility,
        ),
        filled: true,
        fillColor: _passwordFocusNode.hasFocus ? Colors.greenAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
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
          return 'Please enter your password';
        }
        return null;
      },
    );
  }
}
