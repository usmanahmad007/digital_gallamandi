import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'OrderDetailsScreen.dart';

class NotificationScreen extends StatefulWidget {
  final String userId; // ID of the logged-in user
  final bool isSeller; // Determines if the user is a seller or not

  const NotificationScreen({super.key, required this.userId, required this.isSeller});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('notifications').doc(notificationId).update({
        widget.isSeller ? 'sellerIsRead' : 'userIsRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print("${widget.userId}///");

    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text( 'Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('notifications')
            .where(widget.isSeller ? 'sellerId' : 'userId', isEqualTo: widget.userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications available.'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final notificationData = notification.data() as Map<String, dynamic>;
              final isRead = notificationData[widget.isSeller ? 'sellerIsRead' : 'userIsRead'] ?? false;

              return Card(
                elevation: 3,
                color: isRead ? Colors.grey[300] : Colors.white,
                child: ListTile(
                  title: const Text("Order has been Cancelled By Admin"),
                  subtitle: Text('Order ID: ${notificationData['orderId']}'),
                  trailing: Icon(
                    isRead ? Icons.check_circle : Icons.circle,
                    color: isRead ? Colors.green : Colors.grey,
                  ),
                  onTap: () async {
                    // Mark notification as read
                    await markNotificationAsRead(notification.id);

                    // Navigate to Order Details Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsScreen(
                          orderId: notificationData['orderId'],
                          productId: notificationData['productId'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
