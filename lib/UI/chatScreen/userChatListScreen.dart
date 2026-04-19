import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chatScreen.dart';

class UserChatListScreen extends StatefulWidget {
  final String currentUserId;

  const UserChatListScreen({required this.currentUserId, super.key});

  @override
  _UserChatListScreenState createState() => _UserChatListScreenState();
}

class _UserChatListScreenState extends State<UserChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> sellerNamesCache = {};
  bool isFetchingSellerNames = false;

  // Optimized Deletion
  Future<void> _deleteChat(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      debugPrint('Error deleting chat: $e');
    }
  }
  // 1. Define your professional color palette
  final List<Color> _avatarPalette = [
    Colors.blue.shade600,
    Colors.green.shade600,
    Colors.orange.shade600,
    Colors.purple.shade600,
    Colors.teal.shade600,
    Colors.pink.shade600,
    Colors.indigo.shade600,
  ];

  // 2. This helper picks a color based on the name so it stays consistent
  Color _getConsistentColor(String name) {
    if (name.isEmpty || name == "Loading...") return Colors.grey;
    // Uses the name's unique hash to pick an index from the list
    int index = name.hashCode.abs() % _avatarPalette.length;
    return _avatarPalette[index];
  }

  // 3. The updated UI widget
  Widget _buildAvatar(String name) {
    final Color profileColor = _getConsistentColor(name);

    return CircleAvatar(
      radius: 28,
      backgroundColor: profileColor.withOpacity(0.1), // Soft background
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "?",
        style: TextStyle(
          color: profileColor, // Strong text color
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }

  // Returns Future<bool?> to satisfy Dismissible requirement
  Future<bool?> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Remove Chat?'),
        content: const Text('Do you want to delete this conversation?'),
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

  Future<void> _fetchAllSellerNames(List<String> sellerIds) async {
    if (isFetchingSellerNames || sellerIds.isEmpty) return;
    isFetchingSellerNames = true;

    try {
      final sellerDocs = await _firestore
          .collection('saller') // Matches your 'saller' collection name
          .where(FieldPath.documentId, whereIn: sellerIds)
          .get();

      for (var doc in sellerDocs.docs) {
        sellerNamesCache[doc.id] = doc['name'] ?? 'Store';
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error fetching names: $e');
    } finally {
      isFetchingSellerNames = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Inbox', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('chats')
            .where('userId', isEqualTo: widget.currentUserId)
            .orderBy('lastUpdate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final chatDocs = snapshot.data!.docs;

          final sellerIds = chatDocs
              .map((doc) => (doc.data() as Map<String, dynamic>)['sellerId'])
              .where((id) => id != null)
              .toSet()
              .toList()
              .cast<String>();

          if (sellerNamesCache.isEmpty && !isFetchingSellerNames) {
            _fetchAllSellerNames(sellerIds);
          }

          return ListView.separated(
            itemCount: chatDocs.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, endIndent: 20),
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final messages = chatData['messages'] as List? ?? [];
              final lastMsg = messages.isNotEmpty ? messages.last : null;

              final sellerId = chatData['sellerId'] ?? "";
              final sellerName = sellerNamesCache[sellerId] ?? "Loading...";

              // Unread logic: Last message exists AND it wasn't sent by me AND isRead is false
              final isUnread = lastMsg != null &&
                  lastMsg['sender'] != widget.currentUserId &&
                  lastMsg['isRead'] == false;

              return Dismissible(
                key: Key(chatDocs[index].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                ),
                confirmDismiss: (direction) async {
                  return await _confirmDelete(context);
                },
                onDismissed: (direction) => _deleteChat(chatDocs[index].id),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _buildAvatar(sellerName),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          sellerName,
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
                            color: isUnread ? Colors.blue : Colors.grey,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg?['text'] ?? "Start a conversation",
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
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          currentUserId: widget.currentUserId,
                          productId: chatData['productId'],
                          productName: chatData['productName'],
                          sellerId: sellerId,
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


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text("No messages yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  // Same robust time logic to prevent "int is not subtype of Timestamp"
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "Just now";

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      return "";
    }

    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat.jm().format(date);
    }
    return DateFormat.MMMd().format(date);
  }
}