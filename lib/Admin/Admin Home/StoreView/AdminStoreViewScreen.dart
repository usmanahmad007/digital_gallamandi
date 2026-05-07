import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zrai_mart/Admin/Admin%20Home/product/AdminProductFullView.dart';
import '../../../Notification/send_notification.dart';
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
  final Color primaryGreen = const Color(0xFF004D40); // Deep Forest Green
  final Color accentGreen = const Color(0xFF00BFA5);
  final Color bgGray = const Color(0xFFF4F7F6);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Logic: Delete Store ---
  Future<void> _deleteStore() async {
    try {
      var productQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: widget.sellerId)
          .get();

      for (var doc in productQuery.docs) {
        await doc.reference.delete();
      }

      await FirebaseFirestore.instance
          .collection('saller')
          .doc(widget.sellerId)
          .delete();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Merchant data wiped successfully"),
              backgroundColor: Colors.black87),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _showDeleteConfirmation() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Icon(Icons.warning_rounded, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            const Text("Permanent Action", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Are you sure you want to delete this store? This will remove all products and financial records forever.",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel"))),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteStore();
                    },
                    child: const Text("Confirm Delete", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- UI Elements ---

  Widget _buildStatCard(String label, dynamic value, IconData icon, Color color, {bool isMoney = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(radius: 14, backgroundColor: color.withOpacity(0.1), child: Icon(icon, size: 16, color: color)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMoney ? "Rs ${NumberFormat('#,###').format(value ?? 0)}" : "$value",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: primaryGreen.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _openMap(double lat, double long) async {
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$long";
    final Uri uri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Google Maps")),
      );
    }
  }
  Widget _buildLocationTile(Map<String, dynamic> data) {
    // Safe parsing of coordinates
    final double lat = double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0;
    final double lng = double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Align button with text center
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primaryGreen.withOpacity(0.1),
            child: Icon(Icons.map_outlined, size: 20, color: primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Coordinates",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text("Lat: $lat, Long: $lng",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // The Action Button
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => _openMap(lat, lng),
              icon: const Icon(Icons.directions, color: Colors.blue),
              tooltip: "Open in Google Maps",
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('saller').doc(widget.sellerId).snapshots(),
        builder: (context, sellerSnapshot) {
          if (!sellerSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          var sellerData = sellerSnapshot.data?.data() as Map<String, dynamic>? ?? {};

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').where('sellerId', isEqualTo: widget.sellerId).snapshots(),
            builder: (context, orderSnapshot) {
              // Simple logic for counts
              // Update your counting logic like this:
              Map<String, int> counts = {
                "Total": 0,
                "Pending": 0,
                "InProcess": 0, // Added this
                "Shipped": 0,
                "Done": 0,
                "Cancelled": 0,
                "Returned": 0
              };

              if (orderSnapshot.hasData) {
                for (var doc in orderSnapshot.data!.docs) {
                  String s = doc['status'].toString().toLowerCase();
                  counts["Total"] = (counts["Total"] ?? 0) + 1;

                  if (s == 'pending') {
                    counts["Pending"] = (counts["Pending"] ?? 0) + 1;
                  } else if (s == 'in process' || s == 'processing') {
                    // Added logic to catch various "process" naming conventions
                    counts["InProcess"] = (counts["InProcess"] ?? 0) + 1;
                  } else if (s == 'shipped') {
                    counts["Shipped"] = (counts["Shipped"] ?? 0) + 1;
                  } else if (s == 'completed' || s == 'delivered') {
                    counts["Done"] = (counts["Done"] ?? 0) + 1;
                  } else if (s == 'cancelled') {
                    counts["Cancelled"] = (counts["Cancelled"] ?? 0) + 1;
                  } else if (s == 'returned') {
                    counts["Returned"] = (counts["Returned"] ?? 0) + 1;
                  }
                }
              }

              return CustomScrollView(
                slivers: [
                  _buildHeader(sellerData),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Inside your Column in SliverToBoxAdapter
                          const SizedBox(height: 20),
                          _buildSectionTitle("Contact & Location"),
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              children: [
                                _buildInfoTile(Icons.email_outlined, "Email Address", sellerData['email'] ?? "N/A"),
                                const Divider(height: 20),
                                _buildInfoTile(Icons.location_on_outlined, "Store Address",
                                    sellerData['address'] ?? "No address provided"),
                                const Divider(height: 20),
                                // Replace your old _buildInfoTile for coordinates with this:
                                _buildLocationTile(sellerData),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildSectionTitle("Financial Health"),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 110,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildStatCard("Total Earned", sellerData['totalEarnings'], Icons.account_balance_wallet, Colors.blue, isMoney: true),
                                const SizedBox(width: 12),
                                _buildStatCard("Withdrawn", sellerData['totalWithdrawn'], Icons.outbox, Colors.orange, isMoney: true),
                                const SizedBox(width: 12),
                                _buildStatCard("Available", sellerData['balance'], Icons.monetization_on, Colors.green, isMoney: true),
                                const SizedBox(width: 12),
                                _buildStatCard("Pending Withdrawal", sellerData['pendingWithdrawal'], Icons.outbox, Colors.orange, isMoney: true),
                                const SizedBox(width: 12),
                                _buildStatCard("On Hold", sellerData['onHold'], Icons.monetization_on, Colors.green, isMoney: true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionTitle("Order Performance"),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.1,
                            children: [
                              _buildMiniStat("Total", counts["Total"], Colors.blueGrey),
                              _buildMiniStat("Pending", counts["Pending"], Colors.amber),
                              _buildMiniStat("Processing", counts["InProcess"], Colors.deepOrange), // Added UI tile
                              _buildMiniStat("Shipped", counts["Shipped"], Colors.blue),
                              _buildMiniStat("Success", counts["Done"], Colors.green),
                              _buildMiniStat("Returned", counts["Returned"], Colors.brown),
                              _buildMiniStat("Cancelled", counts["Cancelled"], Colors.red),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildPersistentTabs(),
                  _tabController.index == 2 ? _buildFinanceList() : _buildProductGrid(),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              );
            },
          );
        },
      ),
      bottomSheet: _buildBottomDock(),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(data['storeName'] ?? "Merchant", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(data['backgroundImage'] ?? '', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: primaryGreen)),
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.8)]))),
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(radius: 40, backgroundImage: NetworkImage(data['storeLogo'] ?? '')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey[600], letterSpacing: 1.2));
  }

  Widget _buildMiniStat(String label, dynamic value, Color color) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$value", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPersistentTabs() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: primaryGreen,
          unselectedLabelColor: Colors.grey,
          indicator: UnderlineTabIndicator(borderSide: BorderSide(width: 3, color: primaryGreen), insets: const EdgeInsets.symmetric(horizontal: 16)),
          tabs: const [Tab(text: "Products"), Tab(text: "Rentals"), Tab(text: "History")],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').where('sellerId', isEqualTo: widget.sellerId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        final items = snapshot.data!.docs.map((d) => Product.fromDocument(d)).where((p) => p.isRental == (_tabController.index == 1)).toList();

        if (items.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Text("No inventory found."))));

        return SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 15, mainAxisSpacing: 15),
            delegate: SliverChildBuilderDelegate((c, i) => _buildProductCard(items[i]), childCount: items.length),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product p) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminProductFullView(imageUrls: p.imageUrl, productName: p.name, shortDescription: p.description, price: p.price, categoryName: p.category, productId: p.id, isRental: p.isRental, rating: p.avgRate))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), child: Image.network(p.imageUrl[0], fit: BoxFit.cover, width: double.infinity))),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text("Rs ${p.price}", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('withdrawRequests').where('sellerId', isEqualTo: widget.sellerId).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        return SliverList(
          delegate: SliverChildBuilderDelegate((c, i) {
            var doc = snapshot.data!.docs[i];
            bool isApproved = doc['status'] == 'approved';
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: isApproved ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), child: Icon(isApproved ? Icons.check : Icons.history, color: isApproved ? Colors.green : Colors.orange)),
                  const SizedBox(width: 15),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Withdrawal Request", style: const TextStyle(fontWeight: FontWeight.bold)), Text("Ref: ${doc.id.substring(0, 8)}", style: TextStyle(fontSize: 10, color: Colors.grey))])),
                  Text("Rs ${doc['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            );
          }, childCount: snapshot.data!.docs.length),
        );
      },
    );
  }

  Widget _buildBottomDock() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('saller').doc(widget.sellerId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        var data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        bool isRestricted = data['isSellerRestricted'] ?? false;
        String status = data['storeStatus'] ?? "";

        return Container(
          height: 90,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
          child: Row(
            children: [
              if (status == "pending") ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(updates: {'isAdminApproved': true, 'storeStatus': 'editable'}, title: "Store Approved", category: "approved", storeName: data['storeName']),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: const Text("APPROVE STORE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateStatus(updates: {'isSellerRestricted': !isRestricted}, title: isRestricted ? "Merchant Restored" : "Merchant Blocked", category: isRestricted ? "active" : "restricted", storeName: data['storeName']),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: isRestricted ? Colors.green : Colors.orange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: Text(isRestricted ? "UNBLOCK" : "BLOCK", style: TextStyle(color: isRestricted ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: IconButton(onPressed: _showDeleteConfirmation, icon: const Icon(Icons.delete_outline, color: Colors.red)),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateStatus({required Map<String, dynamic> updates, required String title, required String category, required String storeName}) async {
    try {
      await FirebaseFirestore.instance.collection('saller').doc(widget.sellerId).update(updates);
      await sendNotification(senderRole: "admin", senderId: "admin", sellerId: widget.sellerId, userId: null, title: title, body: "Admin has updated your account status.", type: "store", category: category, actionId: widget.sellerId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(title), behavior: SnackBarBehavior.floating, backgroundColor: primaryGreen));
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  // Ensure min and max are exactly the same to avoid layout extent calculation errors
  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Colors.white,
      elevation: overlapsContent ? 4 : 0, // Adds a slight shadow when content scrolls under
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}