import 'package:flutter/material.dart';

import '../../app_colors.dart';
// import 'package:zrai_mart/utils/app_colors.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  _PrivacyPolicyScreenState createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  // --- BACKEND LOGIC PRESERVED ---
  bool isAccepted = false;

  void _onAccept() {
    setState(() {
      isAccepted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for accepting our Privacy Policy!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Icon Header
            const Center(
              child: Icon(
                Icons.gpp_good_rounded,
                size: 80,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 20),

            // Document Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Data Protection & Legal",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 15),
                  _buildPolicyText(
                    "Your data is safe with us. We do not share your personal information with any third parties for commercial purposes.",
                  ),
                  const SizedBox(height: 15),
                  _buildPolicyText(
                    "However, in compliance with legal obligations, we may share your data with the Government of Pakistan if formally requested in accordance with applicable laws.",
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "By using Digital Galla Mandi, you agree to these terms of service.",
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

           /* // Conditional Action Button (Restored and Modernized)
            if (!isAccepted)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Accept Privacy Policy",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
*/
            if (isAccepted==false)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.successGreen),
                    SizedBox(width: 10),
                    Text(
                      "Privacy Policy Accepted",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.successGreen,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textDark,
        height: 1.6,
      ),
    );
  }
}