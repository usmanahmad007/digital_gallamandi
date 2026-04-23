import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/auth/EmailVerificationScreen.dart';
import 'package:zrai_mart/UI/auth/signInScreen.dart';

import '../../app_colors.dart';
// Import your new color file here
// import 'package:zrai_mart/utils/app_colors.dart';

class Signupscreen extends StatefulWidget {
  const Signupscreen({super.key});

  @override
  State<Signupscreen> createState() => _SignupscreenState();
}

class _SignupscreenState extends State<Signupscreen> {
  // --- BACKEND LOGIC PRESERVED ---
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullName = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isAcceptedTerms = false;
  bool _isAcceptedAdmin = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _togglePasswordVisibility() => setState(() => _isPasswordVisible = !_isPasswordVisible);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullName.dispose();
    super.dispose();
  }

  // UI Helper for SnackBar
  void _showFloatingSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // SIGNUP LOGIC (NO CHANGES)
  Future<void> _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_isAcceptedTerms) {
        _showFloatingSnackBar("Please accept terms and conditions", Colors.orange);
        return;
      }
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        User? user = userCredential.user;
        if (user != null) {
          await user.sendEmailVerification();
          String collection = _isAcceptedAdmin ? 'saller' : 'users';
          Map<String, dynamic> userData = {
            'name': _fullName.text,
            'email': _emailController.text,
            'profileImage': null,
            'timestamp': FieldValue.serverTimestamp(),
          };
          if (_isAcceptedAdmin) {
            userData['type'] = "seller";
            userData['balance'] = 0;            // withdrawable
           /* userData['onHold'] = 0;             // processing orders
            userData['totalEarnings'] = 0;      // lifetime earnings
            userData['totalWithdrawn'] = 0;     // total withdrawn
            userData['pendingWithdrawal'] = 0; */ // withdrawal requested

            userData['isAdminApproved'] = false;
            userData['isSellerRestricted'] = false;
            userData['hasSetupStore'] = false;
            userData['storeStatus'] = "editable";

          }
          await _firestore.collection(collection).doc(user.uid).set(userData);
          _showFloatingSnackBar('Signup successful! Verify your email.', AppColors.successGreen);
          Navigator.push(context, MaterialPageRoute(builder: (context) => const EmailVerificationScreen()));
        }
      } catch (e) {
        _showFloatingSnackBar(e.toString(), AppColors.errorRed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header Area
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Image.asset("assets/img_1.png", width: 120, height: 120, color: Colors.white), // Assuming logo can be tinted
                  const Text("Join Digital Galla Mandi", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildInputField(controller: _fullName, hint: "Full Name", icon: Icons.person_outline),
                    const SizedBox(height: 15),
                    _buildInputField(controller: _emailController, hint: "Email Address", icon: Icons.email_outlined),
                    const SizedBox(height: 15),
                    _buildInputField(
                        controller: _passwordController,
                        hint: "Password",
                        icon: Icons.lock_outline,
                        isPassword: true
                    ),
                    const SizedBox(height: 20),

                    // Role Selection & Terms (Modern Layout)
                    _buildCheckOption(
                      title: "Sign up as Seller (Farmer)",
                      value: _isAcceptedAdmin,
                      onChanged: (val) => setState(() => _isAcceptedAdmin = val!),
                    ),
                    _buildCheckOption(
                      title: "I accept Terms & Conditions",
                      value: _isAcceptedTerms,
                      onChanged: (val) => setState(() => _isAcceptedTerms = val!),
                    ),

                    const SizedBox(height: 30),

                    // Modern Signup Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                        ),
                        child: const Text("Create Account", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already a member? "),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Text("Sign In", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Refined Input Field
  Widget _buildInputField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? !_isPasswordVisible : false,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryGreen),
          suffixIcon: isPassword
              ? IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off), onPressed: _togglePasswordVisibility)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
        validator: (value) => (value == null || value.isEmpty) ? "Field required" : null,
      ),
    );
  }

  // Refined Checkbox Option
  Widget _buildCheckOption({required String title, required bool value, required Function(bool?) onChanged}) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textGrey)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryGreen,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}