import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sellerChatScreen.dart';

class SellerChatListScreen extends StatefulWidget {
  const SellerChatListScreen({super.key});

  @override
  _SellerChatListScreenState createState() => _SellerChatListScreenState();
}

class _SellerChatListScreenState extends State<SellerChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, Map<String, String>> userCache = {};
  bool isFetchingUsernames = false;
  String? sellerId;

  @override
  void initState() {
    super.initState();
    sellerId = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<void> _fetchAllUserNames(List<String> userIds) async {
    if (isFetchingUsernames || userIds.isEmpty) return;
    isFetchingUsernames = true;

    try {
      final userDocs = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      for (var doc in userDocs.docs) {
        final data = doc.data();
        userCache[doc.id] = {
          'name': data['name'] ?? 'Unknown User',
          'profileImage': data['profileImage'] ?? '',
        };
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      isFetchingUsernames = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('sellerId', isEqualTo: sellerId)
            .orderBy('lastUpdate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final chatDocs = snapshot.data!.docs;
          final userIds = chatDocs
              .map((doc) => (doc.data() as Map<String, dynamic>)['userId'])
              .where((id) => id != null)
              .toSet()
              .toList()
              .cast<String>();

          if (userCache.isEmpty && !isFetchingUsernames) {
            _fetchAllUserNames(userIds);
          }

          return ListView.separated(
            itemCount: chatDocs.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, endIndent: 20),
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final userId = chatData['userId'] ?? "";

              // Metadata fields from the new structure
              final String lastMessage = chatData['lastMessage'] ?? "";
              final dynamic lastUpdate = chatData['lastUpdate'];

              // Note: For Read Receipts on List, you should ensure your _saveMessage logic
              // in ChatScreen also updates 'lastMessageSender' and 'isLastMessageRead' in the main doc.
              final bool isMe = chatData['lastMessageSender'] == sellerId;
              final bool isRead = chatData['isLastMessageRead'] ?? false;
              final bool isUnreadForMe = !isMe && !isRead;

              final userData = userCache[userId] ?? {'name': 'Loading...', 'profileImage': ''};

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _buildAvatar(userData['name']!, userData['profileImage']),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        userData['name']!,
                        style: TextStyle(
                          fontWeight: isUnreadForMe ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTime(lastUpdate),
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnreadForMe ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                subtitle: Row(
                  children: [

                      Icon(
                        isRead ? Icons.done_all : Icons.check,
                        size: 16,
                        color: isRead ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 4),

                    Expanded(
                      child: Text(
                        lastMessage,
                        style: TextStyle(
                          color: isUnreadForMe ? Colors.black87 : Colors.grey[600],
                          fontWeight: isUnreadForMe ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUnreadForMe)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SellerChatScreen(
                        sellerId: sellerId!,
                        productId: chatData['productId'] ?? '',
                        productName: chatData['productName'] ?? '',
                        userId: userId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String name, String? imageUrl) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.green.withOpacity(0.1),
      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
      child: (imageUrl == null || imageUrl.isEmpty)
          ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?",
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20))
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No conversations found", style: TextStyle(color: Colors.black54, fontSize: 16)),
        ],
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "";
    DateTime date = (timestamp is Timestamp) ? timestamp.toDate() : DateTime.now();
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat.jm().format(date);
    }
    return DateFormat.MMMd().format(date);
  }
}