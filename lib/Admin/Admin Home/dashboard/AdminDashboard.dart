import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/Admin/Admin%20Home/AdminPanelScreen.dart';
import 'package:zrai_mart/Admin/Admin%20Home/category/AdminCategoryScreen.dart';
import 'package:zrai_mart/Admin/Admin%20Home/coupons/AdminCouponScreen.dart';
import '../../../saller center/orderScreen/ProductDetailsScreen.dart';
import '../orderScreen/AdminOrdersScreen.dart';
import '../product/AdminProductScreen.dart';
import '../seller/AdminSellersScreen.dart';
import 'AdminBackend.dart';
import '../../../app_colors.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminBackend _api = AdminBackend();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text("Digital Galla Mandi",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryGreen,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _api.getGlobalStats(),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? {};

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // --- 1. TOP MAIN COUNTS GRID ---
                // --- 1. TOP MAIN COUNTS GRID (Inside CustomScrollView) ---
                _buildSectionHeader("Resource Overview"),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.1,
                    ),
                    delegate: SliverChildListDelegate([
                      _miniStatCard("Farmers", "${stats['totalSellers'] ?? 0}", Colors.green),
                      _miniStatCard("Customers", "${stats['totalUsers'] ?? 0}", Colors.blue),
                      _miniStatCard("Products", "${stats['totalProducts'] ?? 0}", Colors.teal),
                      _miniStatCard("Categories", "${stats['totalCategories'] ?? 0}", Colors.indigo), // New Card
                      _miniStatCard("Blogs", "${stats['totalBlogs'] ?? 0}", Colors.purple),
                      _miniStatCard("Coupons", "${stats['totalCoupons'] ?? 0}", Colors.red),
                      _miniStatCard("Ads Slider", "${stats['totalSliders'] ?? 0}", Colors.amber),
                    ]),
                  ),
                ),

                // --- 2. ORDER STATUS DETAILS ---
                _buildSectionHeader("Order Status Detail"),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.5, // Keep as is or adjust to 2.8 if it looks tight
                    ),
                    delegate: SliverChildListDelegate([
                      // Existing Cards
                      _statusCard("Pending", "${stats['pending'] ?? 0}", Colors.orange),
                      _statusCard("Shipped", "${stats['shipped'] ?? 0}", Colors.blueAccent),
                      _statusCard("Delivered", "${stats['delivered'] ?? 0}", Colors.teal),
                      _statusCard("In Process", "${stats['inProcess'] ?? 0}", Colors.indigo),
                      _statusCard("Completed", "${stats['completed'] ?? 0}", AppColors.primaryGreen),

                      // 🔥 NEW CARDS ADDED HERE
                      _statusCard("Total Orders", "${stats['totalOrders'] ?? 0}", Colors.black87),
                      _statusCard("Cancelled", "${stats['cancelled'] ?? 0}", Colors.red),
                      _statusCard("Returned", "${stats['returned'] ?? 0}", Colors.brown),

                      // Existing Revenue Card
                      _statusCard("Revenue", "Rs.${stats['earnings'] ?? 0}", Colors.deepPurple),
                    ]),
                  ),
                ),

                // --- 3. MANAGEMENT MODULES ---
                _buildSectionHeader("Management Modules"),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    delegate: SliverChildListDelegate([
                      _moduleTile("Sellers", Icons.agriculture, Colors.green, () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSellersScreen()));
                      }),
                      _moduleTile("Users", Icons.people, Colors.blue, () {
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUsersScreen()));
                      }),
                      _moduleTile("Orders", Icons.shopping_cart, Colors.orange, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminOrdersScreen()));
                      }),
                      _moduleTile("Products", Icons.inventory_2, Colors.teal, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProductsScreen()));
                      }),
                      _moduleTile("Blogs", Icons.article, Colors.purple, () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPanelScreen()));
                      }),
                      _moduleTile("Category", Icons.category, Colors.indigo, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCategoryScreen()));                      }),
                      _moduleTile("Coupons", Icons.confirmation_number, Colors.red, () {

                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCouponScreen()));
                        // Add your Coupons Screen here
                      }),
                      _moduleTile("Slider", Icons.linear_scale, Colors.amber, () {
                        // Add your Slider Screen here
                      }),
                      _moduleTile("Chats", Icons.chat, Colors.cyan, () {
                        // Add your Chats Screen here
                      }),
                      _moduleTile("Notify", Icons.notifications_active, Colors.pink, () {
                        // Add your Notification Screen here
                      }),
                    ]),
                  ),
                ),

                // --- 4. RECENT ORDERS ---
                _buildSectionHeader("Live Activity"),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _buildLiveOrderListSliver(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper for Section Headers
  Widget _buildSectionHeader(String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      sliver: SliverToBoxAdapter(
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }

  // Card for Top Counts
  Widget _miniStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  // Card for Order Statuses
  Widget _statusCard(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _moduleTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveOrderListSliver() {
    return StreamBuilder(
      stream: _api.getLiveOrders(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: SizedBox());
        final docs = (snapshot.data as dynamic).docs;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String sId = data['sellerId'] ?? "";

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: InkWell(
                  onTap: () {
                    // Navigate to the Details Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SellerProductDetailsScreen(product: data),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Thumbnail with Status Dot
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  data['image'] ?? "",
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 70, height: 70, color: Colors.grey[100],
                                    child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(data['status']),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // 2. Info Section
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['title'] ?? "Unknown Crop",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),

                                // Dynamic Seller Name Fetch
                                FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('saller').doc(sId).get(),
                                  builder: (context, sellerSnap) {
                                    String sName = "Fetching seller...";
                                    if (sellerSnap.hasData && sellerSnap.data!.exists) {
                                      sName = sellerSnap.data!['name'] ?? "Unknown Seller";
                                    }
                                    return Row(
                                      children: [
                                        const Icon(Icons.storefront, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(sName,
                                              style: TextStyle(fontSize: 12, color: Colors.blueGrey[600])),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "ID: ${data['orderId'].toString().substring(0, 8)}...",
                                  style: TextStyle(fontSize: 10, color: Colors.grey[400], letterSpacing: 1),
                                ),
                              ],
                            ),
                          ),

                          // 3. Price & Qty Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "PKR ${data['totalPrice']}",
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Qty: ${data['quantity']}",
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 10),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: docs.length > 5 ? 5 : docs.length,
          ),
        );
      },
    );
  }

// Helper to get status color
  Color _getStatusColor(dynamic status) {
    String s = status.toString().toLowerCase();
    if (s == 'completed') return AppColors.primaryGreen;
    if (s == 'pending') return Colors.orange;
    if (s == 'in process') return Colors.blue;
    if (s == 'shipped') return Colors.indigo;
    return Colors.grey;
  }

// Helper for status badge inside the list
  Widget _statusSmallBadge(String status) {
    Color color = status.toLowerCase() == 'completed' ? AppColors.primaryGreen : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}