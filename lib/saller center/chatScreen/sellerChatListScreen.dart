import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sellerChatScreen.dart';

class SellerChatListScreen extends StatefulWidget {
  final String sellerId;

  const SellerChatListScreen({required this.sellerId, super.key});

  @override
  _SellerChatListScreenState createState() => _SellerChatListScreenState();
}

class _SellerChatListScreenState extends State<SellerChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> userNamesCache = {};
  bool isFetchingUsernames = false;

  Future<void> _deleteChat(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      debugPrint('Error deleting chat: $e');
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Delete Conversation?'),
        content: const Text('This will permanently remove this chat from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
        userNamesCache[doc.id] = doc['name'] ?? 'Unknown User';
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error fetching user names: $e');
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
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('sellerId', isEqualTo: widget.sellerId)
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

          if (userNamesCache.isEmpty && !isFetchingUsernames) {
            _fetchAllUserNames(userIds);
          }

          return ListView.separated(
            itemCount: chatDocs.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, endIndent: 20),
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final messages = chatData['messages'] as List? ?? [];
              final lastMsg = messages.isNotEmpty ? messages.last : null;

              final userId = chatData['userId'] ?? "";
              final userName = userNamesCache[userId] ?? "Loading...";
              final isUnread = lastMsg != null && lastMsg['sender'] != widget.sellerId && lastMsg['isRead'] == false;

              return Dismissible(
                key: Key(chatDocs[index].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  final bool? confirmed = await _confirmDelete(context);
                  if (confirmed == true) {
                    await _deleteChat(chatDocs[index].id);
                    return true;
                  }
                  return false;
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _buildAvatar(userName),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          userName,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMsg != null)
                        Text(
                          _formatTime(lastMsg['timestamp']),
                          style: TextStyle(
                            fontSize: 12,
                            color: isUnread ? Colors.green : Colors.grey,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg?['text'] ?? "No messages yet",
                          style: TextStyle(
                            color: isUnread ? Colors.black87 : Colors.grey[600],
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SellerChatScreen(
                          sellerId: widget.sellerId,
                          productId: chatData['productId'] ?? '',
                          productName: chatData['productName'] ?? '',
                          userId: userId,
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

  Widget _buildAvatar(String name) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.green.withOpacity(0.1),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "?",
        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Your inbox is empty", style: TextStyle(color: Colors.black54, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- FIXED FORMAT TIME FUNCTION ---
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "Just now";

    DateTime date;

    // Check if it's a Firestore Timestamp
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    }
    // Check if it's an old 'int' timestamp (milliseconds)
    else if (timestamp is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    else {
      return "";
    }

    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat.jm().format(date);
    }
    return DateFormat.MMMd().format(date);
  }
}