import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zrai_mart/app_colors.dart';

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
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String chatId;
  String sellerName = 'Loading...';

  @override
  void initState() {
    super.initState();
    chatId = 'chat_${widget.currentUserId}_${widget.sellerId}_${widget.productId}';
    _fetchSellerName();
    _markMessagesAsRead();
  }

  Future<void> _fetchSellerName() async {
    try {
      DocumentSnapshot doc = await _firestore.collection('saller').doc(widget.sellerId).get();
      if (doc.exists && mounted) {
        setState(() => sellerName = doc['name'] ?? 'Store');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    String textToSend = message.trim();
    _controller.clear();

    try {
      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);

      Map<String, dynamic> messageData = {
        'sender': widget.currentUserId,
        'text': textToSend,
        'isRead': false,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await chatRef.set({
        'productName': widget.productName,
        'productId': widget.productId,
        'sellerId': widget.sellerId,
        'userId': widget.currentUserId,
        'lastMessage': textToSend,
        'lastUpdate': FieldValue.serverTimestamp(),
        'messages': FieldValue.arrayUnion([messageData]),
      }, SetOptions(merge: true));

    } catch (e) {
      debugPrint('Error sending: $e');
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
          if (m['sender'] != widget.currentUserId && m['isRead'] == false) {
            hasUpdates = true;
            return {...m, 'isRead': true};
          }
          return m;
        }).toList();
        if (hasUpdates) await chatRef.update({'messages': updated});
      }
    } catch (e) {
      debugPrint('Error marking read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get primary color from your theme
    final primaryColor = AppColors.primaryGreen;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(sellerName, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildProductPreview(primaryColor),
          Expanded(child: _buildMessageList(primaryColor)),
          _buildInputArea(primaryColor),
        ],
      ),
    );
  }

  Widget _buildProductPreview(Color primary) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('products').doc(widget.productId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(data['imageUrls'][0], width: 50, height: 50, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                    // Updated to Primary Color
                    Text("PKR ${data['price']}", style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageList(Color primary) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('chats').doc(chatId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Say hi to the seller!"));
        }

        List messages = snapshot.data!.get('messages') ?? [];
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[(messages.length - 1) - index];
            return _buildChatBubble(msg, primary);
          },
        );
      },
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, Color primary) {
    bool isMe = msg['sender'] == widget.currentUserId;

    DateTime time;
    dynamic ts = msg['timestamp'];
    if (ts is Timestamp) time = ts.toDate();
    else if (ts is int) time = DateTime.fromMillisecondsSinceEpoch(ts);
    else time = DateTime.now();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              // Updated to Primary Color
              color: isMe ? primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: Radius.circular(isMe ? 15 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 15),
              ),
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
                // Updated Read Receipt to use Primary Color
                Icon(Icons.done_all, size: 14, color: msg['isRead'] == true ? Colors.blue : Colors.grey),
              ]
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInputArea(Color primary) {
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