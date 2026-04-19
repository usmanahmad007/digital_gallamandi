import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zrai_mart/UI/HomeScreen/SearchScreen.dart';
import 'package:zrai_mart/app_colors.dart';
import 'package:zrai_mart/saller%20center/homeScreen/productFullView.dart';
import '../../UI/product/CustomerProductFullView.dart';
import '../../models/Product.dart';

class StorePreviewScreen extends StatefulWidget {
  final String? sellerId;
  const StorePreviewScreen({super.key, this.sellerId});

  @override
  State<StorePreviewScreen> createState() => _StorePreviewScreenState();
}

class _StorePreviewScreenState extends State<StorePreviewScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryGreen = const Color(0xFF1B3D2F);
  bool otherSellerId=true;
  // 1. Update your listener in initState
  @override
  void initState() {
    super.initState();


    if(widget.sellerId==FirebaseAuth.instance.currentUser!.uid){
      otherSellerId=false;
    }
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Check if the index changed and we aren't already building
      if (!_tabController.indexIsChanging) {
        // Use addPostFrameCallback to ensure setState happens AFTER the current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    });
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToFullView(Product product) {
    if(otherSellerId==true){
    Navigator.push(context, MaterialPageRoute(builder: (_) => customerProductfullview(
      imageUrls: product.imageUrl,
      productName: product.name,
      shortDescription: product.description,
      price: product.price,
      categoryName: product.category,
      isRental: product.isRental,
      rating: product.avgRate,
      sellerId: product.sellerId, id: product.id, quantity: product.quantity,
    )));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => HSProductfullview(
        imageUrls: product.imageUrl,
        productName: product.name,
        shortDescription: product.description,
        price: product.price,
        categoryName: product.category,
        productId: product.id,
        isRental: product.isRental,
        rating: product.avgRate,
        sellerId: product.sellerId,
      )));
    }
  }

  Widget _buildStatusOverlay({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 80, color: color),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              if (color == Colors.red) // Only show contact button for restricted
                ElevatedButton.icon(
                  onPressed: () {
                    // Link to your Help/Support screen
                  },
                  icon: const Icon(Icons.support_agent),
                  label: const Text("Contact Support"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],

          ),
        ),
      ),
    );
  }
  // Replace your build method with this cleaner logic
  @override
  Widget build(BuildContext context) {
    // FIX: Use the sellerId passed to the widget.
    // If it's null (e.g., coming from the seller's own dashboard), fallback to current user.
    final String sellerId = widget.sellerId ?? FirebaseAuth.instance.currentUser?.uid ?? "";

    if (sellerId.isEmpty) {
      return const Scaffold(body: Center(child: Text("No Seller ID found")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: StreamBuilder<DocumentSnapshot>(
        key: ValueKey('seller_$sellerId'),
        stream: FirebaseFirestore.instance.collection('saller').doc(sellerId).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) return const Center(child: Text("Error loading store"));
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));

          var sellerData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

          if (sellerData.isEmpty) {
            return const Center(child: Text("Store profile not found"));
          }

          // --- DEBUG PRINTS: Check these in your VS Code / Android Studio Console ---
          debugPrint("--- Seller Status Check ---");
          debugPrint("isAdminApproved: ${sellerData['isAdminApproved']} (${sellerData['isAdminApproved'].runtimeType})");
          debugPrint("status: ${sellerData['storeStatus']} (${sellerData['storeStatus'].runtimeType})");
          debugPrint("isSellerRestricted: ${sellerData['isSellerRestricted']} (${sellerData['isSellerRestricted'].runtimeType})");
          debugPrint("hasSetupStore: ${sellerData['hasSetupStore']} (${sellerData['hasSetupStore'].runtimeType})");

          // --- ROBUST CONVERSION ---
          // We use "== true" to handle cases where the field might be null or a string by accident
          bool isAdminApproved = sellerData['isAdminApproved'] == true;
          String status = sellerData['storeStatus']?.toString().toLowerCase() ?? "";
          bool isRestricted = sellerData['isSellerRestricted'] == true;
          bool hasSetupStore = sellerData['hasSetupStore'] == true;

          // --- 1. Check for Restrictions FIRST (Priority) ---
          if (isRestricted) {
            return _buildStatusOverlay(
              icon: Icons.report_problem_rounded,
              title: "Account Restricted",
              message: "You cannot receive orders or add products until this restriction is removed by our team.",
              color: Colors.red,
            );
          }

          // --- 2. Check for Pending Review ---
          // Notice we check status "pending" or an empty status
          if (!isAdminApproved || status=="pending") {
            return _buildStatusOverlay(
              icon: Icons.hourglass_empty_rounded,
              title: "Store Under Review",
              message: "Our team is currently verifying your details. You will be notified once your store is live.",
              color: Colors.orange,
            );
          }

          // --- 3. Check for Incomplete Setup ---
          if (!hasSetupStore) {
            return _buildStatusOverlay(
              icon: Icons.storefront_outlined,
              title: "Setup Incomplete",
              message: "Please complete your store profile and setup your business details to start selling.",
              color: Colors.blue,
            );
          }

          // If everything is fine, show the store content
          double lat = sellerData['latitude']?.toDouble() ?? 0.0;
          double lng = sellerData['longitude']?.toDouble() ?? 0.0;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernHeader(sellerData),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildModernProfileInfo(sellerData),
                      const SizedBox(height: 12),
                      _buildActionLocationBar(sellerData, lat, lng),
                      const SizedBox(height: 24),

                      // Coupons Section - Using the correct sellerId
                      _buildCouponsSection(sellerId),
                      const SizedBox(height: 20),
                      _buildFakeSearchBar(),
                    ],
                  ),
                ),
              ),
              _buildStickyModernTabs(),
              _buildModernProductGrid(sellerId), // Using the correct sellerId
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

// Separate the coupon stream to keep build() clean
  Widget _buildCouponsSection(String sellerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coupons')
          .where('sellerId', isEqualTo: sellerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Major Steals 💸",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B3D2F))),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: snapshot.data!.docs.asMap().entries.map((entry) {
                  return _buildPromotionBanner(entry.value.data() as Map<String, dynamic>, entry.key);
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFakeSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context)=>SearchScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: Colors.grey[400]),
            const SizedBox(width: 12),
            Text("Search in this store...", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  List<Color> _getDiscountGradient(int discount) {
    // We use primaryGreen (0xFF1B3D2F) as the bottom/end color for all
    const Color baseGreen = Color(0xFF1B3D2F);

    if (discount >= 50) {
      // Royal Look: Purple fading into your Green
      return [const Color(0xFF6A11CB), baseGreen];
    } else if (discount >= 30) {
      // High Energy: Vibrant Amber/Orange fading into your Green
      return [const Color(0xFFFF8F00), baseGreen];
    } else if (discount >= 15) {
      // Forest Look: Lighter Forest Green fading into your Green
      return [const Color(0xFF2E7D32), baseGreen];
    } else {
      // Professional Look: Steel Blue/Grey fading into your Green
      return [const Color(0xFF607D8B), baseGreen];
    }
  }
  Widget _buildPromotionBanner(Map<String, dynamic> data, int key) {
    String expiryDate = "No Expiry";
    if (data['expireDate'] != null) {
      DateTime date = (data['expireDate'] as Timestamp).toDate();
      expiryDate = "${date.day}/${date.month}/${date.year}";
    }

    int discountValue = (data['discount'] ?? 0).toInt();

    // Using the 'key' (index) to ensure each card stays uniquely colored
    List<Color> bannerColors = _getDiscountGradient(discountValue);

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16, bottom: 12, top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bannerColors,
        ),
        boxShadow: [
          BoxShadow(
              color: bannerColors.last.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5)
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -20, top: -20,
              child: Icon(
                  Icons.local_offer_rounded,
                  size: 120,
                  color: Colors.white.withOpacity(0.07)
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(
                          "FLAT $discountValue% OFF",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(expiryDate, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // --- ADDED STORE NAME HERE ---
                  Text(
                    "ZRAI MART EXCLUSIVE",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),

                  Text(
                    data['title'] ?? "Special Offer",
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Valid only for our store items",
                    style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("CODE", style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                          Text(
                              data['couponCode'] ?? "N/A",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _showCouponDialog(context, data['couponCode'] ?? "N/A", data['title'] ?? "Offer"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: bannerColors.last,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text("Claim Now", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  void _showCouponDialog(BuildContext context, String code, String title) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        // Slide from Right to Left
        final curvedValue = Curves.easeInOutBack.transform(anim1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(curvedValue * -200, 0, 0),
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(title, style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Use this code at checkout to redeem your discount!"),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(code, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Colors.blue),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code));
                            Navigator.pop(context); // Close dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Code '$code' copied!"),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: primaryGreen,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- 1. MODERN IMMERSIVE HEADER ---
  Widget _buildModernHeader(Map<String, dynamic> data) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: false,
      elevation: 0,
      stretch: true,
      backgroundColor: primaryGreen,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black26,
          child: const BackButton(color: Colors.white),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              data['backgroundImage'] ?? '',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.green[100]),
            ),
            // Dynamic Gradient Overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black38, Colors.transparent, Colors.black54],
                ),
              ),
            ),
            // Logo floating between banner and profile
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F8F7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(data['storeLogo'] ?? ''),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. MINIMAL PROFILE SECTION ---
  Widget _buildModernProfileInfo(Map<String, dynamic> data) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data['storeName'] ?? "Store Name",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryGreen),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: Colors.blue, size: 20),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "PREMIUM SUPPLIER",
          style: TextStyle(
              color: Colors.green[700],
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2),
        ),
        const SizedBox(height: 12),
        Text(
          data['description'] ?? "No description available.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.4),
          maxLines: 2,
        ),
      ],
    );
  }

  // --- 3. CLEAN ACTION BAR ---
  Widget _buildActionLocationBar(Map<String, dynamic> data, double lat, double lng) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, color: Colors.green[800], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data['address'] ?? "No Address",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          VerticalDivider(color: Colors.grey[300], thickness: 1),
          GestureDetector(
            onTap: () => _launchMaps(lat, lng), // <--- Call the function here
            child: Text(
              "VIEW MAP",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.green[800],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStickyModernTabs() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        Container(
          color: const Color(0xFFF6F8F7), // Matches your scaffold background
          alignment: Alignment.center,
          child: Column(
            children: [
              const Spacer(),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryGreen,
                unselectedLabelColor: Colors.grey[400],
                indicatorSize: TabBarIndicatorSize.label, // Indicator matches text width
                dividerColor: Colors.transparent,
                indicatorWeight: 3.0,
                // Custom Underline Indicator with rounded corners
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 4.0, color: AppColors.primaryGreen),
                  insets: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
                tabs: [
                  _buildTabItem("Products", Icons.grid_view_rounded, 0),
                  _buildTabItem("Rentals", Icons.key_rounded, 1),
                ],
              ),
              // Subtle separation line
              Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.1)),
            ],
          ),
        ),
      ),
    );
  }

// Helper to make the tab content look more modern
  Widget _buildTabItem(String title, IconData icon, int index) {
    bool isSelected = _tabController.index == index;
    return Tab(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. PREMIUM PRODUCT CARDS ---
  Widget _buildModernProductCard(Product product) {
    return GestureDetector(
      onTap: () => _navigateToFullView(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: Stack(
                  children: [
                    Positioned.fill(child: Image.network(product.imageUrl[0], fit: BoxFit.cover)),
                    /*Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.favorite_border, size: 16, color: primaryGreen),
                      ),
                    ),*/
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(product.name,
                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[700], size: 14),
                        const SizedBox(width: 2),
                        Text(product.avgRate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("PKR ${product.price}",
                        style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w900, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color:AppColors.primaryGreen, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                    )
                  ],
                )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildModernProductGrid(String sellerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').where('sellerId', isEqualTo: sellerId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        final list = snapshot.data!.docs.map((d) => Product.fromDocument(d))
            .where((p) => p.isRental == (_tabController.index == 1)).toList();

        if (list.isEmpty) return const SliverToBoxAdapter(child: Center(child: Text("No items available")));

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 16, mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildModernProductCard(list[index]),
              childCount: list.length,
            ),
          ),
        );
      },
    );
  }
  Future<void> _launchMaps(double lat, double lng) async {
    // Use the 'geo:' scheme for Android or 'maps:' for iOS,
    // or just a universal google maps https link:
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Optionally show a snackbar if the map can't be opened
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open the map")),
      );
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final Widget _tabBar;

  // 10px top padding + 10px bottom padding + 50px container = 70px
  @override double get minExtent => 70.0;
  @override double get maxExtent => 70.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: _tabBar);
  }

  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}