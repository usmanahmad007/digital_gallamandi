import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'NotificationDetailScreen.dart';

class UniversalNotificationScreen extends StatelessWidget {
  final String currentUserId;
  final String userRole; // 'customer', 'seller', or 'admin'

  const UniversalNotificationScreen({
    super.key,
    required this.currentUserId,
    required this.userRole
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('notifications');

    // Filter based on who is looking at the screen
    if (userRole == 'admin') {
      query = query.where('isAdmin', isEqualTo: true);
    } else if (userRole == 'seller') {
      query = query.where('sellerId', isEqualTo: currentUserId);
    } else {
      query = query.where('userId', isEqualTo: currentUserId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No notifications found"));

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String docId = docs[index].id;
              final bool isRead = data['isRead'] ?? false;
              final String type = data['type'] ?? 'system';
              final String category = data['category'] ?? '';

              return Card(
                elevation: isRead ? 0 : 2,
                color: isRead ? Colors.grey[50] : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: _buildLeadingIcon(type, category),
                  title: Text(data['title'], style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['body']),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(data['timestamp']),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: !isRead ? const CircleAvatar(radius: 4, backgroundColor: Colors.green) : null,
                  onTap: () => _handleTap(context, docId, data),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLeadingIcon(String type, String category) {
    IconData icon;
    Color color;

    switch (type) {
      case 'order':
        icon = Icons.shopping_bag_outlined;
        color = Colors.blue;
        break;
      case 'store':
        icon = Icons.storefront;
        color = category == 'restricted' ? Colors.red : Colors.orange;
        break;
      case 'product':
        icon = Icons.inventory_2_outlined;
        color = Colors.teal;
        break;
      default:
        icon = Icons.notifications_active_outlined;
        color = Colors.purple;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _handleTap(BuildContext context, String docId, Map<String, dynamic> data) async {
    // 1. Mark as Read in Firestore
    await FirebaseFirestore.instance.collection('notifications').doc(docId).update({'isRead': true});

    // 2. Extract data for navigation
    final String type = data['type'] ?? 'system';
    final String actionId = data['actionId'] ?? '';

    // 3. Generic Navigation to a Detail View
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationDetailScreen(
            type: type,
            actionId: actionId,
            notificationData: data,
          ),
        ),
      );
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "";
    DateTime date = (timestamp as Timestamp).toDate();
    return "${date.day}/${date.month} ${date.hour}:${date.minute}";
  }
}