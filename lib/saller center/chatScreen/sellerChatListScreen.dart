import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'sellerChatScreen.dart';

class SellerChatListScreen extends StatefulWidget {
  final String sellerId;

  const SellerChatListScreen({required this.sellerId, super.key});

  @override
  _SellerChatListScreenState createState() => _SellerChatListScreenState();
}

class _SellerChatListScreenState extends State<SellerChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> userNamesCache = {}; // Cache for usernames
  bool isFetchingUsernames = false; // Prevent multiple fetches
  Future<void> _deleteChat(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).delete();
      print('Chat deleted successfully');
    } catch (e) {
      print('Error deleting chat: $e');
    }
  }

  // Show a confirmation dialog before deleting a chat
  Future<void> _confirmDelete(String chatId) async {
    bool? deleteConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Chat'),
          content: const Text('Are you sure you want to delete this chat?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    // If the user confirms, delete the chat
    if (deleteConfirmed ?? false) {
      _deleteChat(chatId);
    }
  }

  Future<void> _fetchAllUserNames(List<String> userIds) async {
    if (isFetchingUsernames) return; // Prevent multiple fetch calls
    isFetchingUsernames = true;

    try {
      final userDocs = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      for (var doc in userDocs.docs) {
        userNamesCache[doc.id] = doc['name'] ?? 'Unknown User';
      }
      setState(() {}); // Update the UI once usernames are fetched
    } catch (e) {
      print('Error fetching user names: $e');
    } finally {
      isFetchingUsernames = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Chats'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('sellerId', isEqualTo: widget.sellerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final chatDocs = snapshot.data!.docs;

          if (chatDocs.isEmpty) {
            return const Center(child: Text('You have no active chats.'));
          }

          // Extract userIds only once and fetch usernames
          final userIds = chatDocs
              .map((doc) => (doc.data() as Map<String, dynamic>)['userId'])
              .toSet()
              .toList()
              .cast<String>();

          if (userNamesCache.isEmpty && !isFetchingUsernames) {
            _fetchAllUserNames(userIds); // Fetch usernames only once
          }

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final messages = chatData['messages'] as List? ?? [];
              final lastMessage = messages.isNotEmpty ? messages.last : null;

              final lastMessageText = lastMessage?['text'] ?? "No messages yet";
              final isLastMessageRead = lastMessage?['isRead'] ?? true;
              final productName = chatData['productName'] ?? "No product name";
              final userId = chatData['userId'] ?? "Unknown user";
              final productId = chatData['productId'];
              final chatId = chatDocs[index].id;

              // Use cached username or a placeholder
              final userName = userNamesCache[userId] ?? "Loading...";

              // TextStyle based on the `isRead` status
              final textStyle = TextStyle(
                fontWeight: isLastMessageRead ? FontWeight.normal : FontWeight.bold,
              );

              return Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.chat),
                    ),
                    title: Text(
                      userName,
                      style: TextStyle(
                        fontWeight: (chatData['messages'] as List).isNotEmpty &&
                            (chatData['messages'] as List).last['sender'] != widget.sellerId &&
                            !(chatData['messages'] as List).last['isRead']
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      'Last message: $lastMessageText',
                      style: TextStyle(
                        fontWeight: (chatData['messages'] as List).isNotEmpty &&
                            (chatData['messages'] as List).last['sender'] != widget.sellerId &&
                            !(chatData['messages'] as List).last['isRead']
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SellerChatScreen(
                            sellerId: widget.sellerId,
                            productId: productId,
                            productName: productName,
                            userId: userId,
                          ),
                        ),
                      );
                    },
                    onLongPress: (){
                      _confirmDelete(chatId);
                    },
                  ),
                  chatDocs.length>1?
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Container(
                      height: 1,
                      color: Colors.grey,
                    ),
                  ): Container()
                ],
              );

            },
          );

        },
      ),
    );
  }
}
