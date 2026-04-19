import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/Admin/Admin%20Home/product/AdminProductFullView.dart';
import 'package:zrai_mart/app_colors.dart';
import '../../../models/Product.dart';

class AdminStoreReviewScreen extends StatefulWidget {
  final String sellerId;
  const AdminStoreReviewScreen({super.key, required this.sellerId});

  @override
  State<AdminStoreReviewScreen> createState() => _AdminStoreReviewScreenState();
}

class _AdminStoreReviewScreenState extends State<AdminStoreReviewScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryGreen = const Color(0xFF1B3D2F);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Explicit listener to update the UI when swiping or clicking tabs
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Update this to handle multiple fields (like status and approval at once)
// --- Added Notification Method inside _AdminStoreReviewScreenState ---
  Future<void> sendNotification({
    String? sellerId,
    required String title,
    required String body,
    required String type,
    required String category,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'sellerId': sellerId,
        'isAdmin': false,
        'senderId': "ADMIN",
        'title': title,
        'body': body,
        'type': type,
        'category': category,
        'actionId': sellerId ?? "",
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint("Notification Error: $e");
    }
  }

// --- Updated Status Update Method ---
  Future<void> _updateStatus({
    required Map<String, dynamic> updates,
    required String title,
    required String body,
    required String category,
    required String type,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('saller') // Match your 'saller' typo for consistency
          .doc(widget.sellerId)
          .update(updates);

      // Trigger the notification
      await sendNotification(
        sellerId: widget.sellerId,
        title: title,
        body: body,
        type: type,
        category: category,
      );

      _showSnackBar("Store status updated successfully", AppColors.primaryGreen);
    } catch (e) {
      _showSnackBar("Error updating status: $e", Colors.red);
    }
  }

// --- Redesigned Admin Control Panel ---
  Widget _buildAdminControlPanel() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('saller')
          .doc(widget.sellerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        var data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

        bool isApproved = data['isAdminApproved'] ?? false;
        bool isRestricted = data['isSellerRestricted'] ?? false;
        String storeStatus = (data['storeStatus'] ?? "").toString().toLowerCase();
        String storeName = data['storeName'] ?? "Store";

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 25), // Extra bottom padding for safe area
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            border: const Border(top: BorderSide(color: Colors.black12)),
          ),
          child: Row(
            children: [
              // CASE 1: Pending Updates
              if (storeStatus == "pending")
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(
                      updates: {'isAdminApproved': true, 'storeStatus': 'editable'},
                      title: "Updates Approved! ✅",
                      body: "Your recent changes to '$storeName' have been approved and are now visible.",
                      type: "store",
                      category: "approved",
                    ),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text("APPROVE UPDATES"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                )

              // CASE 2: New Store (Initial Setup)
              else if (!isApproved)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(
                      updates: {'isAdminApproved': true, 'storeStatus': 'editable'},
                      title: "Store Approved! 🎉",
                      body: "Congratulations! Your store '$storeName' is now live and ready for customers.",
                      type: "store",
                      category: "approved",
                    ),
                    icon: const Icon(Icons.verified_user),
                    label: const Text("APPROVE STORE"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                )

              // CASE 3: Active Store Management
              else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final bool nextRestrictedState = !isRestricted;
                        _updateStatus(
                          updates: {
                            'isSellerRestricted': nextRestrictedState,
                            'category': nextRestrictedState ? 'restricted' : 'approved',
                          },
                          title: nextRestrictedState ? "Store Restricted ⚠️" : "Restriction Lifted! 🔓",
                          body: nextRestrictedState
                              ? "Your store '$storeName' has been restricted. Please contact support."
                              : "Great news! Your store '$storeName' is active again.",
                          type: "store",
                          category: nextRestrictedState ? "restricted" : "approved",
                        );
                      },
                      icon: Icon(isRestricted ? Icons.lock_open : Icons.block),
                      label: Text(isRestricted ? "UNBLOCK" : "BLOCK"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isRestricted ? Colors.green : Colors.orange,
                        side: BorderSide(color: isRestricted ? Colors.green : Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _showDeleteDialog(),
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                  ),
                ]
            ],
          ),
        );
      },
    );
  }

// --- Delete Dialog Implementation ---
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permanent Delete?"),
        content: const Text("This will remove the seller and all their products. This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit detail view back to list
              // You should call your _deleteSeller logic here
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      bottomNavigationBar: _buildAdminControlPanel(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('saller')
            .doc(widget.sellerId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var sellerData =
              userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          if (sellerData.isEmpty)
            return const Center(child: Text("No data found"));
          String storeStatus = (sellerData['storeStatus'] ?? "").toString().toLowerCase();
          bool hasSetup = sellerData['hasSetupStore'] ?? false;
          bool isApproved = sellerData['isAdminApproved'] ?? false;

          return CustomScrollView(
            slivers: [
              _buildModernHeader(sellerData),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildApprovalStatusBanner(hasSetup, isApproved, storeStatus),
                      const SizedBox(height: 12),
                      _buildModernProfileInfo(sellerData),
                      const SizedBox(height: 24),
                      _buildInfoTile("Email", sellerData['email'] ?? "N/A",
                          Icons.email_outlined),
                      _buildInfoTile("Address", sellerData['address'] ?? "N/A",
                          Icons.location_on_outlined),
                      _buildInfoTile(
                          "Description",
                          sellerData['description'] ?? "N/A",
                          Icons.info_outline),
                    ],
                  ),
                ),
              ),
              _buildStickyTabs(), // The Fixed Tabs
              _buildProductGrid(), // The Reactive Grid
              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          );
        },
      ),
    );
  }

  // --- UPDATED: Fixed Tab Logic ---
  Widget _buildStickyTabs() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        Container(
          color: const Color(0xFFF6F8F7),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryGreen,
            onTap: (index) {
              setState(() {}); // Force rebuild of the grid on tap
            },
            tabs: const [
              Tab(text: "Products"),
              Tab(text: "Rentals"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<QuerySnapshot>(
      // Key is essential here to force StreamBuilder to refresh when tab index changes
      key: ValueKey('grid_tab_${_tabController.index}'),
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: widget.sellerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()));

        final allProducts =
            snapshot.data!.docs.map((d) => Product.fromDocument(d)).toList();

        // Filter: Tab 0 = Products (isRental: false), Tab 1 = Rentals (isRental: true)
        final filteredList = allProducts
            .where((p) => p.isRental == (_tabController.index == 1))
            .toList();

        if (filteredList.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 50),
              child: Center(child: Text("No items found in this category")),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildItemCard(filteredList[index]),
              childCount: filteredList.length,
            ),
          ),
        );
      },
    );
  }

  // --- UI Components ---

  Widget _buildItemCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AdminProductFullView(
                    imageUrls: product.imageUrl,
                    productName: product.name,
                    shortDescription: product.description,
                    price: product.price,
                    categoryName: product.category,
                    productId: product.id,
                    isRental: product.isRental,
                    rating: product.avgRate,isAdmin: true,)));
      },
      child: Card(
        elevation: 0,
        clipBehavior: Clip
            .antiAlias, // Ensures content doesn't bleed out of rounded corners
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image Section with Overlay Rating
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      product.imageUrl.isNotEmpty ? product.imageUrl[0] : '',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                  // Floating Rating Badge
                  if (product.isRental == false)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4)
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              product.avgRate.toString(),
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. Info Section
            Expanded(
              flex: 4,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1B3D2F),
                      ),
                    ),

                    // Category or Type Label
                    Text(
                      product.category ??
                          (product.isRental ? "Rental Service" : "Product"),
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                          fontWeight: FontWeight.w500),
                    ),

                    const Spacer(),

                    // Price Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            "PKR ${product.price}",
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        // Small Decorative Icon
                        const Icon(Icons.arrow_forward_ios,
                            size: 10, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalStatusBanner(bool setup, bool approved, String status) {
    String message = "";
    Color color = Colors.blue;

    if (!setup) {
      message = "Setup Pending";
      color = Colors.grey;
    } else if (status == "pending") {
      message = "Updates Waiting for Review";
      color = Colors.orange;
    } else if (approved) {
      message = "Verified Store";
      color = Colors.green;
    } else {
      message = "Needs Initial Approval";
      color = Colors.blue;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color)),
      child: Row(
        children: [
          Icon(status == "pending" ? Icons.update : (approved ? Icons.verified : Icons.info_outline), color: color),
          const SizedBox(width: 10),
          Text(message,
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }



  Widget _buildInfoTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: primaryGreen, size: 20),
      title:
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      dense: true,
    );
  }

  Widget _buildModernHeader(Map<String, dynamic> data) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(data['backgroundImage'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey)),
            Container(color: Colors.black26),
            Center(
              child: CircleAvatar(
                radius: 46,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                    radius: 43,
                    backgroundImage: NetworkImage(data['storeLogo'] ?? '')),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildModernProfileInfo(Map<String, dynamic> data) {
    return Column(
      children: [
        Text(data['storeName'] ?? "Store Name",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Seller: ${data['name'] ?? 'Unknown'}",
            style: const TextStyle(color: Colors.grey)),
      ],
    );
  }


}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final Widget _tabBar;
  @override
  double get minExtent => 48.0;
  @override
  double get maxExtent => 48.0;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      _tabBar;
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
