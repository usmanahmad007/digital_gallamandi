import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SellerStatsWidget extends StatelessWidget {
  final String sellerId;
  final VoidCallback? onTap;

  const SellerStatsWidget({super.key, required this.sellerId, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric( vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(12), // Tighter padding for a sleek look
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B3D2F).withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('saller').doc(sellerId).snapshots(),
            builder: (context, sellerSnapshot) {
              if (!sellerSnapshot.hasData) {
                return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
              }

              var sellerData = sellerSnapshot.data!.data() as Map<String, dynamic>?;
              if (sellerData == null) return const Center(child: Text("Store not found"));

              String storeName = sellerData['storeName'] ?? "Zrai Mart Partner";
              String logoUrl = sellerData['storeLogo'] ?? "";

              return Row(
                children: [
                  // 1. Premium Logo with Double Ring
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green.withOpacity(0.2), width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFF6F8F7),
                      backgroundImage: logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
                      child: logoUrl.isEmpty ? const Icon(Icons.storefront_outlined, color: Colors.green) : null,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 2. Info Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                storeName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1B3D2F),
                                  letterSpacing: -0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, color: Colors.blue, size: 16),
                          ],
                        ),
                        // Verification Tag
                        Text(
                          "VERIFIED BY DIGITAL GALLA MANDI",
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue.withOpacity(0.8),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Successful Orders Badge
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('orders')
                              .where('sellerId', isEqualTo: sellerId)
                              .snapshots(),
                          builder: (context, orderSnapshot) {
                            int totalOrders = orderSnapshot.hasData ? orderSnapshot.data!.docs.length : 0;
                            return Row(
                              children: [
                                const Icon(Icons.shopping_bag_outlined, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                // FIXED: Wrapped in Expanded to prevent right overflow
                                Expanded(
                                  child: Text(
                                    "$totalOrders Orders Successfully Delivered",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis, // Adds "..." if still too long
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // 3. Modern Pill Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3D2F).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          "Visit",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B3D2F),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF1B3D2F)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}