import 'package:flutter/material.dart';
import '../../app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Terms of Service",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Welcome to Digital Galla Mandi",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "By using this platform, you agree to follow the terms and conditions listed below. "
                  "These terms are designed to ensure a safe and fair marketplace for customers and sellers.",
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 25),

            _buildSection(
              "1. Account Responsibility",
              [
                "Users must provide accurate and complete information when creating an account.",
                "You are responsible for maintaining the confidentiality of your login credentials.",
                "Any activity performed through your account is your responsibility."
              ],
            ),

            _buildSection(
              "2. Orders and Purchases",
              [
                "Customers can place orders through the app using the available payment methods.",
                "Orders may be cancelled by the seller or admin if the product is unavailable or violates marketplace rules.",
                "Customers will receive notifications about order updates."
              ],
            ),

            _buildSection(
              "3. Payments and Refunds",
              [
                "All payments are processed securely through the platform.",
                "If an order is cancelled, refunds will be issued to the original payment method.",
                "Refund processing may take 3–7 working days depending on the payment provider."
              ],
            ),

            _buildSection(
              "4. Seller Responsibilities",
              [
                "Sellers must provide accurate product information and pricing.",
                "Sellers must fulfill orders in a timely manner.",
                "Violation of marketplace policies may result in store restriction or suspension."
              ],
            ),

            _buildSection(
              "5. Prohibited Activities",
              [
                "Posting false or misleading product information.",
                "Selling illegal or restricted products.",
                "Misusing the platform for fraudulent activities."
              ],
            ),

            _buildSection(
              "6. Platform Rights",
              [
                "The platform reserves the right to review, suspend, or remove accounts that violate policies.",
                "Admin may restrict stores or cancel orders if necessary to maintain marketplace integrity."
              ],
            ),

            _buildSection(
              "7. Changes to Terms",
              [
                "These terms may be updated from time to time.",
                "Users will be notified of important updates through the app."
              ],
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                "If you have questions about these Terms of Service, please contact our support team through the Help Center.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          ...points.map(
                (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "• ",
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}