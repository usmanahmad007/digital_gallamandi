import 'package:flutter/material.dart';
import 'package:zrai_mart/saller%20center/profile/PrivacyPolicyScreen.dart';
import 'package:zrai_mart/saller%20center/profile/TermOfServiceUse.dart';

import '../../app_colors.dart';
import 'UserGuideScreen.dart';
// import 'package:zrai_mart/utils/app_colors.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Help Center',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER SECTION ---
            const Text(
              "How can we help you?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              "Find answers to commonly asked questions or contact our support team directly.",
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 25),

            // --- CONTACT ACTION CARDS ---
            Row(
              children: [
                _buildContactCard(Icons.email_outlined, "Email Us", "gallamandidigital@gmail.com"),
                const SizedBox(width: 15),
                _buildContactCard(Icons.chat_outlined, "WhatsApp", "+92 325 7978023"),
              ],
            ),
            const SizedBox(height: 30),

            // --- FAQs SECTION ---
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 15),

            _buildExpandableFAQ(
              'How do I reset my password?',
              ['Open the app', 'Click on "Forgot Password."', 'Enter your registered email to receive instructions.'],
            ),
            _buildExpandableFAQ(
              'How is my data secured?',
              ['Your data is encrypted and stored securely.', 'We do not share data for commercial purposes.', 'We only comply with legal requests from the Government of Pakistan.'],
            ),
            _buildExpandableFAQ(
              'Update profile information?',
              ['Log in to your account.', 'Navigate to "Profile" > "Edit Profile"', 'Make changes and save.'],
            ),
            _buildExpandableFAQ(
              'Technical issues?',
              ['Restart the app', 'Check your internet connection.', 'Clear the app’s cache', 'Contact support with a screenshot if the issue persists.'],
            ),
            _buildExpandableFAQ(
              'My order was cancelled by admin or seller. How will I get my payment back?',
              [
                'If an order is cancelled by the seller or admin, the payment will be refunded automatically.',
                'The refund will be processed to the same payment method used during checkout.',
                'You will receive a notification once the refund process has started.'
              ],
            ),

            _buildExpandableFAQ(
              'How long does it take to receive a refund after order cancellation?',
              [
                'Refunds are usually processed within 3–7 working days.',
                'The exact time depends on your bank or payment provider.',
                'If the refund takes longer, you can contact support with your order ID.'
              ],
            ),

            _buildExpandableFAQ(
              'What should I do if I have not received my refund?',
              [
                'Check your bank statement or payment wallet first.',
                'Ensure the refund processing time (3–7 working days) has passed.',
                'If you still have not received it, contact support with your order details.'
              ],
            ),

            _buildExpandableFAQ(
              'When do sellers receive payment for completed orders?',
              [
                'Seller earnings are added to the store balance after an order is successfully completed.',
                'Payments are held until the delivery is confirmed and the return period has passed.',
                'This helps ensure a safe transaction for both buyers and sellers.'
              ],
            ),

            _buildExpandableFAQ(
              'How can sellers withdraw their earnings?',
              [
                'Sellers can request a withdrawal from the store dashboard.',
                'Go to Seller Panel > Wallet / Earnings > Withdraw.',
                'Enter the withdrawal amount and confirm the request.'
              ],
            ),

            _buildExpandableFAQ(
              'How long does seller withdrawal take?',
              [
                'Withdrawals are usually processed within 2–5 working days.',
                'Processing time may vary depending on the payment method.',
                'You will receive a notification when the withdrawal is completed.'
              ],
            ),

            _buildExpandableFAQ(
              'Why is my store restricted or under review?',
              [
                'Stores may be restricted if platform policies are violated.',
                'The admin team reviews store activities to ensure marketplace safety.',
                'You will receive a notification explaining the reason and possible next steps.'
              ],
            ),

            _buildExpandableFAQ(
              'How can I contact support for order or payment issues?',
              [
                'Use the email or WhatsApp contact provided in the Help Center.',
                'Include your order ID or store details for faster assistance.',
                'Our support team will review your request and respond as soon as possible.'
              ],
            ),

            const SizedBox(height: 30),

            // --- RESOURCES SECTION ---
            _buildSectionHeader("Resources"),
            _buildResourceTile(Icons.menu_book_outlined, "User Guide", "Step-by-step app instructions",() {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserGuideScreen(),
                ),
              );}),
            _buildResourceTile(Icons.privacy_tip_outlined, "Privacy Policy", "How we handle your data",() {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );}),
            _buildResourceTile(Icons.gavel_outlined, "Terms of Service", "Usage rules and guidelines",() {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );}),

            const SizedBox(height: 30),

            // --- FEEDBACK FOOTER ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1)),
              ),
              child: const Column(
                children: [
                  Text(
                    "Give us Feedback",
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Your thoughts help us improve. Share your experience with us!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 28),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableFAQ(String question, List<String> answers) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
        children: answers.map((a) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("• ", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
              Expanded(child: Text(a, style: const TextStyle(color: AppColors.textGrey, fontSize: 14))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
    );
  }

  Widget _buildResourceTile(
      IconData icon,
      String title,
      String sub,
      VoidCallback onTap,
      ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryGreen, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        sub,
        style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.textGrey,
      ),
      onTap: onTap,
    );
  }
}