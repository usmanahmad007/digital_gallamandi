import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBackend {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. User & Seller Management ---
  Stream<QuerySnapshot> getFarmers() => _db.collection('sellers').snapshots();
  Stream<QuerySnapshot> getCustomers() => _db.collection('users').snapshots();

  // --- 2. Orders & Products ---
  Stream<QuerySnapshot> getLiveOrders() => _db.collection('orders').orderBy('timestamp', descending: true).snapshots();
  Stream<QuerySnapshot> getProducts() => _db.collection('products').snapshots();

  // --- 3. Marketing (Slider, Coupons, Blogs) ---
  Stream<QuerySnapshot> getSliders() => _db.collection('slider').snapshots();
  Stream<QuerySnapshot> getCoupons() => _db.collection('coupons').snapshots();
  Stream<QuerySnapshot> getBlogs() => _db.collection('blogs').snapshots();

  // --- 4. System (Categories, Notifications) ---
  Stream<QuerySnapshot> getCategories() => _db.collection('category').snapshots();

  // --- Global Actions ---
  Future<void> updateStatus(String collection, String docId, String status) async {
    await _db.collection(collection).doc(docId).update({'status': status});
  }

  Future<void> deleteItem(String collection, String docId) async {
    await _db.collection(collection).doc(docId).delete();
  }
  // Add this to your MandiBackend class
  Stream<Map<String, dynamic>> getGlobalStats() {
    return FirebaseFirestore.instance.collection('orders').snapshots().asyncMap((orderSnap) async {
      final sellerSnap = await FirebaseFirestore.instance.collection('saller').get();
      final userSnap = await FirebaseFirestore.instance.collection('users').get();
      final productSnap = await FirebaseFirestore.instance.collection('products').get();
      final blogSnap = await FirebaseFirestore.instance.collection('blogs').get();
      final sliderSnap = await FirebaseFirestore.instance.collection('slider').get();
      final couponSnap = await FirebaseFirestore.instance.collection('coupons').get();
      final categorySnap = await FirebaseFirestore.instance.collection('category').get();

      double totalEarnings = 0;
      int pending = 0;
      int shipped = 0;
      int delivered = 0;
      int completed = 0;
      int inProcess = 0;

      // 🔥 NEW COUNTERS
      int cancelled = 0;
      int returned = 0;

      for (var doc in orderSnap.docs) {
        String status = (doc['status'] ?? '').toString().toLowerCase();
        double price = (doc['totalPrice'] ?? 0).toDouble();

        if (status == 'pending') {
          pending++;
        } else if (status == 'in process') {
          inProcess++;
        } else if (status == 'shipped') {
          shipped++;
          // 🔥 Add to earnings because item is on the way
          totalEarnings += price;
        } else if (status == 'delivered') {
          delivered++;
        } else if (status == 'completed') {
          completed++;
          // 🔥 Add to earnings because order is finished
          totalEarnings += price;
        } else if (status == 'cancelled') {
          cancelled++;
        } else if (status == 'returned') {
          returned++;
        }
      }

      return {
        'totalSellers': sellerSnap.docs.length,
        'totalUsers': userSnap.docs.length,
        'totalProducts': productSnap.docs.length,
        'totalBlogs': blogSnap.docs.length,
        'totalSliders': sliderSnap.docs.length,
        'totalCoupons': couponSnap.docs.length,
        'totalCategories': categorySnap.docs.length,

        // Order Totals
        'totalOrders': orderSnap.docs.length, // Already implemented
        'earnings': totalEarnings,
        'pending': pending,
        'shipped': shipped,
        'delivered': delivered,
        'completed': completed,
        'inProcess': inProcess,

        // 🔥 NEW KEYS FOR UI
        'cancelled': cancelled,
        'returned': returned,
      };
    });
  }
}