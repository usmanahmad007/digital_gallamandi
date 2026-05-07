import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../Notification/send_notification.dart';
import '../../app_colors.dart';

class SellerChatScreen extends StatefulWidget {
  final String sellerId;
  final String productId;
  final String productName;
  final String userId;

  const SellerChatScreen({
    super.key,
    required this.sellerId,
    required this.productId,
    required this.productName,
    required this.userId,
  });

  @override
  State<SellerChatScreen> createState() => _SellerChatScreenState();
}

class _SellerChatScreenState extends State<SellerChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  late String chatId;
  String userName = 'Customer';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Maintain consistency with Customer side ID structure
    chatId = 'chat_${widget.userId}_${widget.sellerId}_${widget.productId}';
    _fetchUserName();
    _markMsgFirst();
  }
  Future<void> _markMsgFirst() async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);

      // 1. Get the document snapshot
      DocumentSnapshot snapshot = await chatRef.get();

      if (snapshot.exists) {
        // 2. Access the data from the snapshot
        var data = snapshot.data() as Map<String, dynamic>;

        // 3. Compare the field
        if (data['lastMessageSender'] != widget.sellerId) {
          // Update logic here
          await chatRef.update({'isLastMessageRead': true});
        }
      }
    } catch (e) {
      debugPrint("Error marking chat as read: $e");
    }
  }

  Future<void> _fetchUserName() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.userId).get();
      if (userDoc.exists && mounted) {
        setState(() => userName = userDoc['name'] ?? 'Customer');
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }
  }

  // --- CORE MESSAGE LOGIC (SUB-COLLECTION STRUCTURE) ---

  Future<void> _saveMessage({
    required String text,
    required String type,
    String? imageUrl,
  }) async {
    if (text.isEmpty && imageUrl == null) return;

    final batch = _firestore.batch();

    // 1. Reference to sub-collection
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('seller-customer-messages')
        .doc();

    // 2. Reference to chat metadata (Main doc)
    final chatRef = _firestore.collection('chats').doc(chatId);

    final messageData = {
      'sender': widget.sellerId,
      'text': text,
      'url': imageUrl ?? '',
      'type': type,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final metadataUpdate = {
      'productId': widget.productId,
      'productName': widget.productName,
      'sellerId': widget.sellerId,
      'userId': widget.userId,
      'lastMessage': type == 'image' ? '📷 Photo' : text,
      'lastUpdate': FieldValue.serverTimestamp(),
      'lastMessageSender': widget.sellerId, // Add this
      'isLastMessageRead': false,
    };

    batch.set(messageRef, messageData);
    batch.set(chatRef, metadataUpdate, SetOptions(merge: true));

    try {
      await batch.commit();

      // Trigger Notification to Customer
      await sendNotification(
        senderId: widget.sellerId,
        senderRole: 'seller',
        userId: widget.userId,
        title: "Message from Store",
        body: type == 'image' ? "Sent a photo regarding ${widget.productName}" : text,
        type: "message",
        category: "chat",
        actionId: chatId,
      );
    } catch (e) {
      debugPrint("Batch commit error: $e");
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1000,
    );

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        String fileName = 'chat/$chatId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

        await storageRef.putFile(File(pickedFile.path));
        String downloadUrl = await storageRef.getDownloadURL();

        await _saveMessage(text: '📷 Photo', type: 'image', imageUrl: downloadUrl);
      } catch (e) {
        debugPrint('Upload Error: $e');
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  // ... existing imports

  // --- UPDATED MARK AS READ LOGIC ---

  void _markAsRead(List<QueryDocumentSnapshot> docs) {
    final batch = _firestore.batch();
    bool needsUpdate = false;

    // 1. Identify messages sent by the Customer that are unread
    final unreadDocs = docs.where((d) =>
    d['sender'] != widget.sellerId && d['isRead'] == false
    ).toList();

    if (unreadDocs.isNotEmpty) {
      for (var doc in unreadDocs) {
        batch.update(doc.reference, {'isRead': true});
      }
      needsUpdate = true;
    }





    if (needsUpdate) {
      batch.commit().catchError((e) => debugPrint("Error updating read status: $e"));
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
          return const Center(child: Text("No messages yet."));
        }

        final docs = snapshot.data!.docs;

        // Trigger the read receipt logic whenever the stream updates
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _markAsRead(docs);
        });

        return ListView.builder(
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

  // ... rest of your code (_saveMessage, _pickImage, etc.)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(color: Colors.green, minHeight: 2),
          Expanded(child: _buildMessageStream()),
          _buildInputArea(),
        ],
      ),
    );
  }



  Widget _buildChatBubble(Map<String, dynamic> msg) {
    final bool isMe = msg['sender'] == widget.sellerId;
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImage(url: url))),
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
              cacheWidth: 440,
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
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                  hintText: "Message customer...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              backgroundColor: AppColors.primaryGreen,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  final text = _controller.text.trim();
                  if (text.isNotEmpty) {
                    _saveMessage(text: text, type: 'text');
                    _controller.clear();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String url;
  const FullScreenImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
      body: Center(
        child: InteractiveViewer(
          child: Hero(tag: url, child: Image.network(url, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}