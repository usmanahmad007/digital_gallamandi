import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  String userName = '';

  @override
  void initState() {
    super.initState();
    chatId = 'chat_${widget.userId}_${widget.sellerId}_${widget.productId}';
    _fetchUserName();
    CheckMarkedMessage();
    _sendMessage("Anyone Available to chat?".toString());
  }

  Future<void> _fetchUserName() async {
    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'] ?? 'Unknown User';
        });
      } else {
        print('User not found');
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
  }

  Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      final document = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (document.exists) {
        return document.data() as Map<String, dynamic>;
      } else {
        print('Product not found');
        return null;
      }
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    try {
      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);
      DocumentSnapshot chatSnapshot = await chatRef.get();

      if (!chatSnapshot.exists) {
        await chatRef.set({
          'productId': widget.productId,
          'sellerId': widget.sellerId,
          'userId': widget.userId,
          'messages': [],
        });
      }

      Map<String, dynamic> messageData = {
        'sender': widget.sellerId,
        'text': message,
        'isRead': false
      };

      await chatRef.update({
        'messages': FieldValue.arrayUnion([messageData]),
      });

      _controller.clear();
      setState(() {});
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Widget _buildMessage(String sender, String text, isRead, length, index, docId) {
    bool isSeller = sender == widget.sellerId;

    return Align(
      alignment: isSeller ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: isSeller ? Colors.green : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSeller ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName.isNotEmpty ? userName : widget.userId),
      ),
      body: Column(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: getProductById(widget.productId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error fetching product data'));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('Product not found'));
              } else {
                final productData = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.green.shade300,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.black,
                        )
                    ),
                    child: ListTile(
                      leading: productData['imageUrls'] != null &&
                          (productData['imageUrls'] as List).isNotEmpty
                          ? Image.network(
                        productData['imageUrls'][0],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                          : const Icon(Icons.image_not_supported, size: 50),
                      title: Text(
                        productData['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),maxLines: 1,overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(productData['description'] ?? 'No Description', style: const TextStyle(color: Colors.white),maxLines: 1,overflow: TextOverflow.ellipsis,),
                          const SizedBox(height: 5),
                          Text(
                            '\$${productData['price'] ?? '0'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                              maxLines: 1,overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      trailing: Text(
                        productData['category'] ?? 'N/A',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('chats').doc(chatId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chatData = snapshot.data!.data() as Map<String, dynamic>?;
                List messages = chatData?['messages'] ?? [];
                messages = messages.reversed.toList();

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessage(
                      message['sender'],
                      message['text'],
                      message['isRead'] ?? false,
                      messages.length,
                      index,
                      snapshot.data!.id,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(50)
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () => _sendMessage(_controller.text.toString()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> CheckMarkedMessage() async {
    try {
      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);

      DocumentSnapshot snapshot = await chatRef.get();
      if (snapshot.exists) {
        Map<String, dynamic>? chatData =
        snapshot.data() as Map<String, dynamic>?;
        if (chatData != null && chatData['messages'] is List) {
          List messages = chatData['messages'];

          List updatedMessages = messages.map((message) {
            if (message['sender'] != widget.sellerId &&
                message['isRead'] == false) {
              return {
                ...message,
                'isRead': true,
              };
            }
            return message;
          }).toList();

          await chatRef.update({'messages': updatedMessages});
          print("Marked all unread messages as read.");
        } else {
          _sendMessage("Anyone Available to chat?".toString());
        }
      } else {
        _sendMessage("Anyone Available to chat?".toString());
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
}
