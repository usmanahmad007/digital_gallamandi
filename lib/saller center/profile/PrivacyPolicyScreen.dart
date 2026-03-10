import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  _PrivacyPolicyScreenState createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool isAccepted = false;

  void _onAccept() {
    setState(() {
      isAccepted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for accepting our Privacy Policy!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Privacy Policy",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Your data is safe with us. We do not share your personal information with any third parties for commercial purposes.\n\n"
                  "However, in compliance with legal obligations, we may share your data with the Government of Pakistan if formally requested in accordance with applicable laws.\n\n"
                  ,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
           /* if (!isAccepted)
              ElevatedButton(
                onPressed: _onAccept,
                child: Text("Accept Privacy Policy"),
              ),
            if (isAccepted)
              Text(
                "Privacy Policy Accepted ✅",
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),*/
          ],
        ),
      ),
    );
  }
}