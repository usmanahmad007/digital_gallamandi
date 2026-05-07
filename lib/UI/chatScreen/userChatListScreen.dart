import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chatScreen.dart';

class UserChatListScreen extends StatefulWidget {
  const UserChatListScreen({super.key});

  @override
  _UserChatListScreenState createState() => _UserChatListScreenState();
}

class _UserChatListScreenState extends State<UserChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, Map<String, String>> sellerCache = {};
  bool isFetchingSellerNames = false;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<void> _deleteChat(String chatId) async {
    try {
      // Note: This deletes metadata. In a full production app,
      // you might also want to delete the sub-collection messages.
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      debugPrint('Error deleting chat: $e');
    }
  }

  Future<void> _fetchAllSellerNames(List<String> sellerIds) async {
    if (isFetchingSellerNames || sellerIds.isEmpty) return;
    isFetchingSellerNames = true;
    try {
      final sellerDocs = await _firestore
          .collection('saller')
          .where(FieldPath.documentId, whereIn: sellerIds)
          .get();

      for (var doc in sellerDocs.docs) {
        final data = doc.data();
        sellerCache[doc.id] = {
          'name': data['name'] ?? 'Store',
          'profileImage': data['profileImage'] ?? '',
        };
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
        stream: _firestore
            .collection('chats')
            .where('userId', isEqualTo: currentUserId)
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

          if (sellerCache.isEmpty && !isFetchingSellerNames) {
            _fetchAllSellerNames(sellerIds);
          }

          return ListView.separated(
            itemCount: chatDocs.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, endIndent: 20),
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final sellerId = chatData['sellerId'] ?? "";

              // --- Metadata Logic ---
              final String lastMsg = chatData['lastMessage'] ?? "Start a conversation";
              final dynamic lastUpdate = chatData['lastUpdate'];
              final String lastSender = chatData['lastMessageSender'] ?? "";
              final bool isRead = chatData['isLastMessageRead'] ?? false;

              final bool isMe = lastSender == currentUserId;
              final bool isUnreadForMe = !isMe && !isRead;
              debugPrint("$isMe/$isRead/$isUnreadForMe");

              final sellerData = sellerCache[sellerId] ?? {'name': 'Loading...', 'profileImage': ''};

              return Dismissible(
                key: Key(chatDocs[index].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                ),
                confirmDismiss: (direction) async => await _confirmDelete(context),
                onDismissed: (direction) => _deleteChat(chatDocs[index].id),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _buildAvatar(sellerData['name']!, sellerData['profileImage']),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          sellerData['name']!,
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
                          color: isUnreadForMe ? Colors.blue : Colors.grey,
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
                          lastMsg,
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
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          currentUserId: currentUserId!,
                          productId: chatData['productId'] ?? '',
                          productName: chatData['productName'] ?? '',
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

  // --- UI Helper Methods ---

  Widget _buildAvatar(String name, String? imageUrl) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.blue.withOpacity(0.1),
      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
      child: (imageUrl == null || imageUrl.isEmpty)
          ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?",
          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 22))
          : null,
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

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "";
    DateTime date = (timestamp is Timestamp) ? timestamp.toDate() : DateTime.now();
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat.jm().format(date);
    }
    return DateFormat.MMMd().format(date);
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Remove Chat?'),
        content: const Text('Do you want to delete this conversation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}