import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chatScreen.dart';

class UserChatListScreen extends StatefulWidget {
  final String currentUserId;

  const UserChatListScreen({required this.currentUserId, super.key});

  @override
  _UserChatListScreenState createState() => _UserChatListScreenState();
}

class _UserChatListScreenState extends State<UserChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> sellerNamesCache = {}; // Cache for seller names
  bool isFetchingSellerNames = false; // Prevent multiple fetches
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    // Set up a periodic refresh every 20 seconds
    refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      setState(() {}); // Trigger a rebuild of the screen
    });
  }

  @override
  void dispose() {
    // Cancel the timer to avoid memory leaks
    refreshTimer?.cancel();
    super.dispose();
  }
  // Fetch all seller names based on the list of seller IDs
  Future<void> _fetchAllSellerNames(List<String> sellerIds) async {
    if (isFetchingSellerNames) return; // Prevent multiple fetch calls
    isFetchingSellerNames = true;

    try {
      final sellerDocs = await _firestore
          .collection('saller')
          .where(FieldPath.documentId, whereIn: sellerIds)
          .get();

      for (var doc in sellerDocs.docs) {
        sellerNamesCache[doc.id] = doc['name'] ?? 'Unknown Seller';
      }
      setState(() {}); // Update UI once names are fetched
    } catch (e) {
      print('Error fetching seller names: $e');
    } finally {
      isFetchingSellerNames = false;
    }
  }

  // Method to delete a chat
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Chats'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('chats')
            .where('userId', isEqualTo: widget.currentUserId)
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

          // Extract sellerIds only once and fetch seller names
          final sellerIds = chatDocs
              .map((doc) => (doc.data() as Map<String, dynamic>)['sellerId'])
              .toSet()
              .toList()
              .cast<String>();

          // Fetch seller names only if not already cached
          if (sellerNamesCache.isEmpty && !isFetchingSellerNames) {
            _fetchAllSellerNames(sellerIds); // Fetch seller names only once
          }

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final messages = chatData['messages'] as List? ?? [];
              final lastMessage = messages.isNotEmpty ? messages.last : null;

              final lastMessageText = lastMessage?['text'] ?? "No messages yet";
              final isLastMessageRead = lastMessage?['isRead'] ?? false;
              final productName = chatData['productName'] ?? "No product name";
              final sellerId = chatData['sellerId'] ?? "Unknown seller";
              final productId = chatData['productId'];
              final chatId = chatDocs[index].id;

              // Use cached seller name or a placeholder
              final sellerName = sellerNamesCache[sellerId] ?? "Loading...";

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
                      sellerName,
                      style: TextStyle(
                        fontWeight: (chatData['messages'] as List).isNotEmpty &&
                            (chatData['messages'] as List).last['sender'] != widget.currentUserId &&
                            !(chatData['messages'] as List).last['isRead']
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      'Last message: $lastMessageText',

                      style: TextStyle(
                        fontWeight: (chatData['messages'] as List).isNotEmpty &&
                            (chatData['messages'] as List).last['sender'] != widget.currentUserId &&
                            !(chatData['messages'] as List).last['isRead']
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            currentUserId: widget.currentUserId,
                            productId: productId,
                            productName: productName,
                            sellerId: sellerId,
                          ),
                        ),
                      );
                    },
                    onLongPress: () {
                      _confirmDelete(chatId); // Confirm deletion of the chat
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
