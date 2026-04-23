import 'package:flutter/material.dart';
import '../../app_colors.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "User Guide",
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
              "Customer Guide",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 15),

            _buildGuide(
              Icons.person_add_alt_1,
              "Create an Account",
              [
                "Open the app and tap Sign Up.",
                "Enter your name, email, and password.",
                "Verify your account if required.",
                "Login to start using the app.",
              ],
            ),

            _buildGuide(
              Icons.search,
              "Browse Products",
              [
                "Use the Home screen to explore products.",
                "Search for specific products using the search bar.",
                "Tap a product to view price, images, and details.",
              ],
            ),

            _buildGuide(
              Icons.shopping_cart_checkout,
              "Place an Order",
              [
                "Open the product page.",
                "Tap Add to Cart or Buy Now.",
                "Enter your delivery address and contact details.",
                "Confirm the order to complete purchase.",
              ],
            ),

            _buildGuide(
              Icons.local_shipping,
              "Track Orders",
              [
                "Go to My Orders from your profile.",
                "View order status such as Pending, Processing, Shipped, or Completed.",
                "Notifications will inform you when the order status changes.",
              ],
            ),

            _buildGuide(
              Icons.payments,
              "Refund After Cancellation",
              [
                "If an order is cancelled by seller or admin, a refund will be processed automatically.",
                "Refunds usually take 3–7 working days.",
                "The refund will be returned to the original payment method.",
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Seller Guide",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 15),

            _buildGuide(
              Icons.storefront,
              "Register as a Seller",
              [
                "Create an account in the app.",
                "Apply to open a seller store.",
                "Submit required store details.",
                "Wait for admin approval before selling.",
              ],
            ),

            _buildGuide(
              Icons.inventory_2,
              "Add Products",
              [
                "Open Seller Dashboard.",
                "Tap Add Product.",
                "Upload product images.",
                "Enter title, description, category, and price.",
                "Publish the product to make it visible to customers.",
              ],
            ),

            _buildGuide(
              Icons.receipt_long,
              "Manage Orders",
              [
                "Open Seller Panel > Orders.",
                "View orders placed by customers.",
                "Update order status such as Processing, Shipped, or Completed.",
                "Customers will receive notifications automatically.",
              ],
            ),

            _buildGuide(
              Icons.account_balance_wallet,
              "Seller Earnings",
              [
                "Earnings are added to the seller wallet after order completion.",
                "Funds may remain on hold until the return period ends.",
              ],
            ),

            _buildGuide(
              Icons.attach_money,
              "Withdraw Earnings",
              [
                "Go to Seller Dashboard > Wallet or Earnings.",
                "Select Withdraw.",
                "Enter withdrawal amount.",
                "Submit withdrawal request.",
                "Withdrawals are processed within 2–5 working days.",
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGuide(IconData icon, String title, List<String> steps) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
          child: Icon(icon, color: AppColors.primaryGreen),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.textDark,
          ),
        ),
        childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
        children: steps
            .map(
              (step) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
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
                    step,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            .toList(),
      ),
    );
  }
}