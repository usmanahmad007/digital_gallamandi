import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  _SellerChatScreenState createState() => _SellerChatScreenState();
}

class _SellerChatScreenState extends State<SellerChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String chatId;
  String userName = 'Loading...';

  @override
  void initState() {
    super.initState();
    chatId = 'chat_${widget.userId}_${widget.sellerId}_${widget.productId}';
    _fetchUserName();
    _markMessagesAsRead();
  }

  Future<void> _fetchUserName() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.userId).get();
      if (userDoc.exists && mounted) {
        setState(() => userName = userDoc['name'] ?? 'Customer');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // --- UPDATED LOGIC FOR TIMESTAMPS ---
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    String textToSend = message.trim();
    _controller.clear();

    try {
      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);

      // Prepare the message object
      Map<String, dynamic> messageData = {
        'sender': widget.sellerId,
        'text': textToSend,
        'isRead': false,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // COMBINE EVERYTHING: Metadata + Message Array in ONE request
      await chatRef.set({
        'productId': widget.productId,
        'productName': widget.productName,
        'sellerId': widget.sellerId,
        'userId': widget.userId,
        'lastMessage': textToSend,
        'lastUpdate': FieldValue.serverTimestamp(),
        'messages': FieldValue.arrayUnion([messageData]), // Combined here!
      }, SetOptions(merge: true));

    } catch (e) {
      debugPrint('Send Error: $e');
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);
      DocumentSnapshot snap = await chatRef.get();
      if (snap.exists) {
        List messages = snap.get('messages') ?? [];
        bool hasUpdates = false;
        List updated = messages.map((m) {
          if (m['sender'] != widget.sellerId && m['isRead'] == false) {
            hasUpdates = true;
            return {...m, 'isRead': true};
          }
          return m;
        }).toList();
        if (hasUpdates) await chatRef.update({'messages': updated});
      }
    } catch (e) {
      debugPrint('Read Status Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('chats').doc(chatId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("No messages yet"));
        }

        List messages = snapshot.data!.get('messages') ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          reverse: true, // Newest at bottom
          itemCount: messages.length,
          itemBuilder: (context, index) {
            // Get messages in reverse order for the 'reverse: true' ListView
            final msg = messages[(messages.length - 1) - index];
            return _buildChatBubble(msg);
          },
        );
      },
    );
  }

  // --- UPDATED BUBBLE WITH TYPE SAFETY ---
  Widget _buildChatBubble(Map<String, dynamic> msg) {
    bool isMe = msg['sender'] == widget.sellerId;

    DateTime time;
    dynamic ts = msg['timestamp'];

    if (ts is Timestamp) {
      time = ts.toDate();
    } else if (ts is int) {
      // Handles the millisecondsSinceEpoch we just implemented
      time = DateTime.fromMillisecondsSinceEpoch(ts);
    } else {
      time = DateTime.now();
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isMe ? Colors.green : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              msg['text'] ?? '',
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(DateFormat.jm().format(time), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(Icons.done_all, size: 12, color: msg['isRead'] == true ? Colors.blue : Colors.grey),
              ]
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Message...",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            // Updated Send Button to Primary Color
            backgroundColor: AppColors.primaryGreen,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(_controller.text),
            ),
          ),
        ],
      ),
    );
  }
}