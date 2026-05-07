import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:zrai_mart/app_colors.dart';
import '../../Notification/send_notification.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String productId;
  final String productName;
  final String sellerId;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.productId,
    required this.productName,
    required this.sellerId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  late String chatId;
  String sellerName = 'Store';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Unique ID combining User, Seller and Product context
    chatId = 'chat_${widget.currentUserId}_${widget.sellerId}_${widget.productId}';
    _fetchSellerName();
    _markMsgFirst();
  }
  Future<void> _markMsgFirst()async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);

      // 1. Get the document snapshot
      DocumentSnapshot snapshot = await chatRef.get();

      if (snapshot.exists) {
        // 2. Access the data from the snapshot
        var data = snapshot.data() as Map<String, dynamic>;

        // 3. Compare the field
        if (data['lastMessageSender'] != widget.currentUserId) {
          // Update logic here
          await chatRef.update({'isLastMessageRead': true});
        }
      }
    } catch (e) {
      debugPrint("Error marking chat as read: $e");
    }
  }

  Future<void> _fetchSellerName() async {
    try {
      DocumentSnapshot doc = await _firestore.collection('saller').doc(widget.sellerId).get();
      if (doc.exists && mounted) {
        setState(() => sellerName = doc['name'] ?? 'Store');
      }
    } catch (e) {
      debugPrint('Error fetching seller name: $e');
    }
  }

  // --- CORE MESSAGE LOGIC ---

  Future<void> _saveMessage({
    required String text,
    required String type,
    String? imageUrl,
  }) async {
    if (text.isEmpty && imageUrl == null) return;

    final batch = _firestore.batch();

    // 1. Reference to sub-collection for messages
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('seller-customer-messages')
        .doc();

    // 2. Reference to chat metadata
    final chatRef = _firestore.collection('chats').doc(chatId);

    final messageData = {
      'sender': widget.currentUserId,
      'text': text,
      'url': imageUrl ?? '',
      'type': type,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final metadataUpdate = {
      'productName': widget.productName,
      'productId': widget.productId,
      'sellerId': widget.sellerId,
      'userId': widget.currentUserId,
      'lastMessage': type == 'image' ? '📷 Photo' : text,
      'lastUpdate': FieldValue.serverTimestamp(),
      'lastMessageSender': widget.currentUserId, // Add this
      'isLastMessageRead': false,
    };

    batch.set(messageRef, messageData);
    batch.set(chatRef, metadataUpdate, SetOptions(merge: true));

    try {
      await batch.commit();

      // Trigger Notification
      await sendNotification(
        senderId: widget.currentUserId,
        senderRole: 'customer',
        sellerId: widget.sellerId,
        title: type == 'image' ? "New Photo from Customer" : "New Support Message",
        body: type == 'image' ? "Sent a photo regarding ${widget.productName}" : text,
        type: "message",
        category: "chat",
        actionId: chatId,
      );
    } catch (e) {
      debugPrint("Message Send Error: $e");
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1200, // Reasonable limit for production
    );

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        String fileName = 'chat/${chatId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

        await storageRef.putFile(File(pickedFile.path));
        String downloadUrl = await storageRef.getDownloadURL();

        await _saveMessage(text: '📷 Photo', type: 'image', imageUrl: downloadUrl);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to upload image")));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  // ... existing imports

  // --- UPDATED MARK AS READ LOGIC ---

  void _markAsRead(List<QueryDocumentSnapshot> docs) {
    // 1. Identify messages sent by the OTHER person that are still unread
    final unreadDocs = docs.where((d) =>
    d['sender'] != widget.currentUserId && d['isRead'] == false
    ).toList();

    // even if there are no unread individual messages, we should ensure
    // the main metadata reflects that the chat has been opened.

    final batch = _firestore.batch();
    bool needsUpdate = false;

    // Update individual messages
    if (unreadDocs.isNotEmpty) {
      for (var doc in unreadDocs) {
        batch.update(doc.reference, {'isRead': true});
      }
      needsUpdate = true;
    }



    if (needsUpdate) {
      batch.commit().catchError((e) => debugPrint("Error marking as read: $e"));
    }
  }

  // --- UPDATED MESSAGE STREAM ---

  Widget _buildMessageStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .doc(chatId)
          .collection('seller-customer-messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No messages yet. Start a conversation!"));
        }

        final docs = snapshot.data!.docs;

        // CRITICAL: This triggers every time a new message arrives or screen opens
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _markAsRead(docs);
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          reverse: true,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildChatBubble(data);
          },
        );
      },
    );
  }

  // ... rest of your code (saveMessage, pickImage, UI widgets)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(sellerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(color: Colors.green, minHeight: 2),
          _buildProductHeader(),
          Expanded(child: _buildMessageStream()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('products').doc(widget.productId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(data['imageUrls'][0], width: 45, height: 45, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1),
                    Text("PKR ${data['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildChatBubble(Map<String, dynamic> msg) {
    final bool isMe = msg['sender'] == widget.currentUserId;
    final String type = msg['type'] ?? 'text';
    final DateTime time = (msg['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final bool isRead = msg['isRead'] ?? false;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primaryGreen : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: type == 'text'
                ? Padding(
              padding: const EdgeInsets.all(12),
              child: Text(msg['text'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
            )
                : _buildImageBubble(msg['url']),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat.jm().format(time), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                      isRead ? Icons.done_all : Icons.check,
                      size: 15,
                      color: isRead ? Colors.blue : Colors.grey
                  ),
                ]
              ],
            ),

          ),
        ],
      ),
    );
  }

  Widget _buildImageBubble(String url) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageView(url: url))),
      child: Hero(
        tag: url,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: RepaintBoundary(
            child: Image.network(
              url,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
              cacheWidth: 440, // Optimizes memory usage
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 220, height: 220, color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.green), onPressed: _pickImage),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: const TextStyle(fontSize: 15),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.green),
              onPressed: () {
                final text = _controller.text.trim();
                if (text.isNotEmpty) {
                  _saveMessage(text: text, type: 'text');
                  _controller.clear();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final String url;
  const FullScreenImageView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
      body: Center(
        child: InteractiveViewer(
          child: Hero(tag: url, child: Image.network(url)),
        ),
      ),
    );
  }
}