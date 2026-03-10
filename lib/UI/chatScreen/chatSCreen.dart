import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String productId;
  final String productName;
  final String sellerId;

  const ChatScreen({super.key,
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
  String userName = '';

  @override
  void initState() {
    super.initState();
    chatId = 'chat_${widget.currentUserId}_${widget.sellerId}_${widget.productId}';
    _fetchUserName();
    CheckMarkedMessage();
  }


  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    try {
      // Reference to the chat document
      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);
      DocumentSnapshot chatSnapshot = await chatRef.get();

      // If the chat document doesn't exist, create it with an empty messages array
      if (!chatSnapshot.exists) {
        print("Chat document doesn't exist. Creating new document.");
        await chatRef.set({
          'productName': widget.productName,
          'productId': widget.productId,
          'sellerId': widget.sellerId,
          'userId': widget.currentUserId,
          'messages': [], // Initialize the messages array as empty
        });
        print("Chat document created with empty messages array.");
      }

      // Prepare the message data (without the timestamp)
      Map<String, dynamic> messageData = {
        'sender': widget.currentUserId,
        'text': message,
        'isRead':false
      };

      print("Sending message: $messageData");

      // Check if the 'messages' field is an array
      if (chatSnapshot.exists && chatSnapshot.data() != null) {
        final data = chatSnapshot.data() as Map<String, dynamic>;

        if (data.containsKey('messages') && data['messages'] is List) {
          // Update the chat document by adding the new message to the array
          await chatRef.update({
            'messages': FieldValue.arrayUnion([messageData]),
          });
          print("Message sent successfully.");
        } else {
          print("Error: Messages field is not an array.");
          // If messages is not an array, you can handle the error or reinitialize it
        }
      }

      // Clear the input field after sending the message
      _controller.clear();

    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> _fetchUserName() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('saller').doc(widget.sellerId).get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'] ?? 'Unknown User';  // Replace 'name' with the actual field name in your Firestore
          print(userName);
        });
      } else {
        print('User not found');
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
  }







  Widget _buildMessage(String sender, String text, bool isRead, int index, String docId) {
    bool isCurrentUser = sender == widget.currentUserId;



    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.green : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isCurrentUser ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
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
  void _markMessageAsRead(int index, String docId) async {
    try {
      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);

      DocumentSnapshot snapshot = await chatRef.get();
      if (snapshot.exists) {
        Map<String, dynamic>? chatData = snapshot.data() as Map<String, dynamic>?;
        if (chatData != null && chatData['messages'] is List) {
          List messages = List.from(chatData['messages']);
          messages[index]['isRead'] = true; // Mark the specific message as read

          await chatRef.update({'messages': messages});
        }
      }
    } catch (e) {
      print('Error updating message read status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
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
                            'PKR:${productData['price'] ?? '0'}',
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
                   /* bool isCurrentUser =  message['sender'] == widget.sellerId;
                    if(messages.length-1==index && isCurrentUser==false && message['isRead']==false){
                      _markMessageAsRead(index, snapshot.data!.id);
                    }*/

                    return _buildMessage(
                      message['sender'],
                      message['text'],
                      message['isRead']??false,
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
                    icon: const Icon(Icons.send, color: Colors.white),
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
        Map<String, dynamic>? chatData = snapshot.data() as Map<String, dynamic>?;
        if (chatData != null && chatData['messages'] is List) {
          List messages = List.from(chatData['messages']);

          // Create a new list with updated messages
          List updatedMessages = messages.map((message) {
            if (message['sender'] != widget.currentUserId && message['isRead'] == false) {
              return {
                ...message,
                'isRead': true, // Mark the message as read
              };
            }
            return message;
          }).toList();

          // Update the messages array in Firestore
          await chatRef.update({'messages': updatedMessages});
          print(updatedMessages.toList());
          print("Marked all unread messages as read.");
        }
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
}
