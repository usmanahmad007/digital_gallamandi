import 'package:flutter/material.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help Center',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Welcome to the Help Center! Here you’ll find answers to commonly asked questions and resources to assist you with your experience.",
            ),
            const Divider(height: 32, thickness: 1),
            const Text(
              'Contact Us',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('- Email: gallamandidigital@gmail.com'),
            const Text('- Phone: +92-123-456-7890 (Available Monday to Friday, 9 AM - 5 PM PKT)'),
            const Text('- Live Chat: Access live support through our WhatsApp +92-123-456-7890'),
            const Divider(height: 32, thickness: 1),
            const Text(
              'Frequently Asked Questions (FAQs)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildFAQItem('How do I reset my password?', [
              'Open the app',
              'Click on "Forgot Password."',
              'Enter your registered email address, and we’ll send you instructions to reset your password.',
            ]),
            _buildFAQItem('How is my data secured?', [
              'Your data is encrypted and stored securely.',
              'We do not share your data with third parties for commercial purposes.',
              'However, we comply with legal requests from the Government of Pakistan when required.',
            ]),
            _buildFAQItem('How do I update my profile information?', [
              'Log in to your account.',
              'Navigate to "Profile" > "Edit Profile"',
              'Make changes and save your updated information.',
            ]),
            _buildFAQItem('What should I do if I encounter a technical issue?', [
              'Restart the app',
              'Ensure you have a stable internet connection.',
              'Clear the app’s cache',
              'If the issue persists, contact us at gallamandidigital@gmail.com with a screenshot or error message.',
            ]),
            const Divider(height: 32, thickness: 1),
            const Text(
              'Resources',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('- User Guide: A detailed step-by-step guide on using our app is available here.'),
            const Text('- Privacy Policy: Read about how we handle your data in our Privacy Policy.'),
            const Text('- Terms of Service: Understand the rules and guidelines of using our services in our Terms of Service.'),
            const Divider(height: 32, thickness: 1),
            const Text(
              'Feedback',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Your feedback helps us improve! Share your thoughts with us by filling out our Feedback Form or Email to us at gallamandidigital@gmail.com'),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Thank you for choosing our services. We’re here to help!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, List answers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          question,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...answers.map((answer) => Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text('- $answer'),
        )),
      ],
    );
  }
}

