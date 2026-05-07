

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zrai_mart/Notification/Notification.dart';
import 'package:zrai_mart/saller%20center/homeScreen/productFullView.dart';
import 'package:zrai_mart/saller%20center/homeScreen/seeAllScreen.dart';
import 'package:zrai_mart/saller%20center/homeScreen/seeAllScreenRental.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:zrai_mart/saller%20center/orderScreen/sallerOrdersScreen.dart';

import '../../UI/Categories/CategoryList.dart';
import '../../UI/HomeScreen/SearchScreen.dart';
import '../../UI/HomeScreen/weather/weather.dart';
import '../../app_colors.dart';
import '../../crop_ai_models/crop_disease_detection/crop_predict_screen.dart';
import '../../crop_ai_models/crop_recommendation/soil_detail_screen.dart';
import '../../models/Product.dart';
import '../chatScreen/sellerChatListScreen.dart';
import '../profile/HelpCenterScreen.dart';
import 'RecomandedProductsScreen.dart';

class sallerHomescreen extends StatefulWidget {
  const sallerHomescreen({super.key});

  @override
  State<sallerHomescreen> createState() => _sallerHomescreenState();
}

class _sallerHomescreenState extends State<sallerHomescreen> {
  final List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = "All";
  bool isNew = false;
  int count = 0;
  int stepcount = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 && !_isLoading) {
        _loadMoreProducts();
      }
    });
    fetchNewMessages();
  }

  // [LOGIC REMAINS UNCHANGED]
  void fetchNewMessages() {
    FirebaseFirestore.instance.collection('chats').where('sellerId', isEqualTo: FirebaseAuth.instance.currentUser!.uid).snapshots().listen((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        List<Map<String, dynamic>> messages = fetchMessagesFromData(data);
        stepcount = 0;
        for (var message in messages) {
          if (message['isRead'] == false && message['sender'] != FirebaseAuth.instance.currentUser!.uid) {
            stepcount = 1;
            isNew = true;
            if (mounted) setState(() {});
            break;
          }
        }
        count = count + stepcount;
      }
    });
  }

  List<Map<String, dynamic>> fetchMessagesFromData(Map<String, dynamic> data) {
    if (data.containsKey('messages') && data['messages'] is List) {
      return List<Map<String, dynamic>>.from(data['messages']);
    }
    return [];
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch all sellers who are approved and NOT restricted
      QuerySnapshot sellerSnapshot = await FirebaseFirestore.instance
          .collection('saller') // Make sure this matches your collection name "saller"
          .where('isAdminApproved', isEqualTo: true)
          .where('isSellerRestricted', isEqualTo: false)
          .where('hasSetupStore', isEqualTo: true)
          .get();

      // 2. Create a list of valid Seller IDs
      List<String> validSellerIds = sellerSnapshot.docs.map((doc) => doc.id).toList();

      // 3. Fetch products
      QuerySnapshot productSnapshot = await FirebaseFirestore.instance.collection('products').get();

      final fetchedProducts = productSnapshot.docs
          .map((doc) => Product.fromDocument(doc))
          .where((product) {
        // 4. ONLY keep product if the seller is in our "Valid" list
        return validSellerIds.contains(product.sellerId);
      }).toList();

      setState(() {
        _products.clear();
        _products.addAll(fetchedProducts);
        _applyCategoryFilter();
        _isLoading = false;
      });

      _lastDocument = productSnapshot.docs.isNotEmpty ? productSnapshot.docs.last : null;
    } catch (e) {
      debugPrint("Error loading products: $e");
      setState(() => _isLoading = false);
    }
  }

  void _applyCategoryFilter() {
    setState(() {
      // This now filters from the already validated _products list
      if (_selectedCategory == "All") {
        _filteredProducts = _products
            .where((product) => product.category != "Rental")
            .toList();
      } else {
        _filteredProducts = _products
            .where((product) =>
        product.category == _selectedCategory &&
            product.category != "Rental")
            .toList();
      }

      // Limit to 10 for the initial view as per your original logic
      _filteredProducts = _filteredProducts.take(10).toList();
    });
  }
  Future<void> _loadMoreProducts() async {
    if (_lastDocument == null) return;
    setState(() => _isLoading = true);
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('products').startAfterDocument(_lastDocument!).limit(10).get();
    final fetchedProducts = querySnapshot.docs.map((doc) => Product.fromDocument(doc)).toList();
    setState(() {
      _products.addAll(fetchedProducts);
      _applyCategoryFilter();
      _isLoading = false;
    });
    _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFA), // Very light green tint for freshness
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDynamicCouponSection(),
                _buildQuickActionsRow(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Text("AI Farming Tools 🚀",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B3D2F))),
                ),
                _buildAiFeatureGrid(context),
                _buildSectionHeader("Specialized Machinery", "Rental", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SeeAllScreenRental()));
                }),
                _buildModernRentalSlider(),

                const SizedBox(height: 10),
                _buildSectionHeader("Premium Supplies", "Market", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SeeAllScreen()));
                }),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: CategoryList(
                    onCategorySelected: (category) {
                      setState(() {
                        _selectedCategory = category;
                        _applyCategoryFilter();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildEnhancedProductCard(_filteredProducts[index]),
                childCount: _filteredProducts.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
  Widget _buildAiFeatureGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // CROP RECOMMENDATION CARD
          Expanded(
            child: _buildLargeActionCard(
              context,
              title: "Crop Selection",
              subtitle: "Best crop for your soil",
              icon: Icons.psychology_outlined,
              color: Colors.blue.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecommandedProductsScreen()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // DISEASE DETECTION CARD
          Expanded(
            child: _buildLargeActionCard(
              context,
              title: "Plant Doctor",
              subtitle: "Scan crop diseases",
              icon: Icons.camera_enhance_rounded,
              color: Colors.teal.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CropPredictScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeActionCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 18,
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color.withOpacity(0.9),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final user = FirebaseAuth.instance.currentUser;

    return SliverAppBar(
      // 1. PINNED FALSE: This allows the entire bar (including bottom) to scroll off-screen.
      pinned: false,
      // 2. FLOATING TRUE: Makes the app bar reappear as soon as the user scrolls up.
      floating: true,
      // 3. SNAP TRUE: Adds an animation that "snaps" the bar into view fully when scrolling up.
      snap: true,

      expandedHeight: 140,
      elevation: 0,
      backgroundColor: Colors.green[700],

      // This defines how the background (Profile/Greeting) fades out
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax, // Adds a subtle parallax animation
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[800]!, Colors.green[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),

          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('saller')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              String userName = "User";
              String? profileImg;

              if (snapshot.hasData && snapshot.data!.exists) {
                final userData = snapshot.data!;
                userName = userData['name'] ?? 'User';
                profileImg = userData['profileImage'];
              }

              return Padding(
                padding: const EdgeInsets.only(left: 20, top: 45),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26, // Slightly larger than the inner radius (24 + 2 for the border)
                      backgroundColor: Colors.white, // This becomes your border color
                      child: CircleAvatar(
                        radius: 24, // Your original size
                        backgroundColor: Colors.grey[200], // Fallback background color
                        backgroundImage: profileImg != null
                            ? NetworkImage(profileImg)
                            : const AssetImage('assets/img_2.png') as ImageProvider,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getGreetingMessage(),
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                          ),
                          Text(
                            userName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 80),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        _buildAppIcon(Icons.notifications_none_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalNotificationScreen(currentUserId: _auth.currentUser!.uid, userRole: 'seller',)))),
        _buildChatIcon(),
        const SizedBox(width: 10),
      ],
      // The Search Bar is attached to 'bottom' and will now hide completely
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: _buildNewSearchBar(),
        ),
      ),
    );
  }
  Widget _buildAppIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onTap,
    );
  }

  Widget _buildChatIcon() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SellerChatListScreen())),
      child: Stack(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.chat_bubble_outline, color: Colors.white),
          ),
          if (isNew)
            Positioned(right: 5, top: 5, child: CircleAvatar(radius: 5, backgroundColor: Colors.orange[700])),
        ],
      ),
    );
  }

  Widget _buildNewSearchBar() {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen(isSeller: true,))),
      child: Container(
        height: 45,
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.green[700], size: 20),
            const SizedBox(width: 10),
            const Text("Find seeds, fertilizers or tractors...", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // 1. The Stream Section that fetches the data
  Widget _buildDynamicCouponSection() {
    return StreamBuilder<QuerySnapshot>(
      // Fetching all available coupons for the customer
      stream: FirebaseFirestore.instance.collection('coupons').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // Hide if no coupons exist
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text("Exclusive Deals 💸",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B3D2F))),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: snapshot.data!.docs.asMap().entries.map((entry) {
                  return _buildPromotionBanner(
                      entry.value.data() as Map<String, dynamic>,
                      entry.key
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

// 2. The Updated Banner UI (integrated from your code)
  Widget _buildPromotionBanner(Map<String, dynamic> data, int key) {
    String expiryDate = "No Expiry";
    if (data['expireDate'] != null) {
      DateTime date = (data['expireDate'] as Timestamp).toDate();
      expiryDate = "${date.day}/${date.month}/${date.year}";
    }
    String storeName=data['storeName'];

    int discountValue = (data['discount'] ?? 0).toInt();
    List<Color> bannerColors = _getDiscountGradient(discountValue);

    return Container(
      width: 320, // Slightly wider for home screen
      margin: const EdgeInsets.only(right: 16, bottom: 12, top: 12),
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
              child: Icon(Icons.local_offer_rounded, size: 120, color: Colors.white.withOpacity(0.07)),
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
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text("FLAT $discountValue% OFF",
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
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
                  Text("${storeName.toUpperCase()} EXCLUSIVE",
                      style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  Text(data['title'] ?? "Special Offer",
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("CODE", style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                          Text(data['couponCode'] ?? "N/A",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _showCouponDialog(context, data['couponCode'] ?? "N/A", data['title'] ?? "Offer"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: bannerColors.last,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              title: Text(title, style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
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
                          icon: const Icon(Icons.copy_rounded, color: AppColors.primaryGreen),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code));
                            Navigator.pop(context); // Close dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Code '$code' copied!"),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.primaryGreen,
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

// 3. Gradient Helper (Required for the banner)
  List<Color> _getDiscountGradient(int discount) {
    const Color baseGreen = Color(0xFF1B3D2F);
    if (discount >= 50) return [const Color(0xFF6A11CB), baseGreen];
    if (discount >= 30) return [const Color(0xFFFF8F00), baseGreen];
    return [const Color(0xFF2E7D32), baseGreen];
  }

  Widget _buildQuickActionsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionItem(Icons.wb_sunny_outlined, "Weather", Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherScreen()))),
          _buildActionItem(Icons.science_outlined, "Soil Test", Colors.blue, () =>Navigator.push(context, MaterialPageRoute(builder: (_) => const SoilDetailsScreen()))),
          _buildActionItem(Icons.history, "Orders", Colors.purple, () =>Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerOrderScreen()))),
          _buildActionItem(Icons.support_agent, "Help", Colors.red, () =>Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()))),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String tag, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B3D2F))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(5)),
                child: Text(tag, style: TextStyle(color: Colors.green[700], fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          GestureDetector(
            onTap: onTap,
            child: Text("See All", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildModernRentalSlider() {
    final rentals = _products.where((p) => p.category == "Rental").toList();
    if (rentals.isEmpty) return const SizedBox(height: 100, child: Center(child: Text("Loading items...")));

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: rentals.length,
        itemBuilder: (context, index) {
          final p = rentals[index];
          return GestureDetector(
            onTap: () => _navigateToFullView(p),
            child: Container(
              width: 240,

              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(p.imageUrl[0], width: double.infinity, fit: BoxFit.cover),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                        Text("PKR ${p.price}/hr", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w900)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedProductCard(Product product) {
    return GestureDetector(
      onTap: () => _navigateToFullView(product),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), // Softer, more modern corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. MASSIVE IMAGE SECTION (Flex 8)
            Expanded(
              flex: 8,
              child: Stack(
                children: [
                  Positioned.fill(

                    child: Image.network(
                      product.imageUrl[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey[100], child: const Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                  // Premium look for Wishlist button
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.favorite_border, size: 18, color: Colors.green[800]),
                    ),
                  ),
                ],
              ),
            ),


            // 2. CLEAN CONTENT SECTION (Flex 3)
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title: 2 lines, no description
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1B3D2F),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Rating & Price Group
                    Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star_rounded, color: Colors.orange[400], size: 16),
                            const SizedBox(width: 2),
                            Text(
                              product.avgRate,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "PKR ${product.price}",
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ),
                            // Modernized "Add" Button
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green[700],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 18),
                            )
                          ],
                        ),
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

  void _navigateToFullView(Product product) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => HSProductfullview(
      imageUrls: product.imageUrl,
      productName: product.name,
      shortDescription: product.description,
      price: product.price,
      categoryName: product.category,
      sellerId: product.sellerId,
      isRental: product.isRental,
      rating: product.avgRate, productId: product.id,
    )));
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌿';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }
}
