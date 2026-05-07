import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/Admin/Admin%20Home/support/AdminChatListScreen.dart';
import '../../Notification/NotificationDetailScreen.dart';

class AdminNotificationScreen extends StatelessWidget {
  const AdminNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Fetching from AdminNotifications
    // 2. Removed the .where('isAdmin') filter because seller-to-admin docs have isAdmin: false
    Query query = FirebaseFirestore.instance
        .collection('AdminNotifications')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Admin Notifications",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No notifications found", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String docId = doc.id;

              bool isRead = data['adminIsRead'] ?? false;
              final String type = data['type'] ?? 'system';
              final String category = data['category'] ?? '';

              return Card(
                elevation: isRead ? 0 : 2,
                color: isRead ? Colors.grey[50] : Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: isRead ? Colors.grey.shade200 : Colors.green.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: _buildLeadingIcon(type, category),
                  title: Text(
                    data['title'] ?? "Notification",
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['body'] ?? "",
                        style: TextStyle(color: Colors.grey[800], fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(data['timestamp']),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: !isRead
                      ? const CircleAvatar(
                    radius: 4,
                    backgroundColor: Colors.green,
                  )
                      : null,
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
      case 'payment':
        icon = Icons.account_balance_wallet_outlined;
        color = Colors.green;
        break;
      case 'message':
      case 'chat':
        icon = Icons.chat_bubble_outline_rounded;
        color = Colors.indigo;
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

  Future<void> _handleTap(
      BuildContext context, String docId, Map<String, dynamic> data) async {
    // CRITICAL FIX: Updated collection name to AdminNotifications
    await FirebaseFirestore.instance
        .collection('AdminNotifications')
        .doc(docId)
        .update({'adminIsRead': true});

    final String type = data['type'] ?? 'system';
    final String actionId = data['actionId'] ?? '';

    if (!context.mounted) return;

    // Handle Chat/Message Navigation
    if (type == 'message' || type == 'chat') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminChatListScreen()),
      );
      return;
    }

    // Default Navigation for other notifications (like Withdrawals)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationDetailScreen(
          type: type,
          actionId: actionId,
          notificationData: data,
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "";
    DateTime date = (timestamp as Timestamp).toDate();
    String minute = date.minute.toString().padLeft(2, '0');
    return "${date.day}/${date.month} ${date.hour}:$minute";
  }
}