import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Admin/Admin Home/support/AdminChatService.dart';
import '../Notification/send_notification.dart';

class ChatWithAdminScreen extends StatefulWidget {
  const ChatWithAdminScreen({super.key});

  @override
  State<ChatWithAdminScreen> createState() => _ChatWithAdminScreenState();
}

class _ChatWithAdminScreenState extends State<ChatWithAdminScreen> {
  final AdminChatService chatService = AdminChatService();
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late String userId;
  late String chatId;
  bool _isFirstLoad = true; // 🔥 Added to track the first load
  double _lastViewInset = 0;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    chatId = "${userId}_admin";



    FirebaseFirestore.instance
        .collection("messages")
        .where("chatId", isEqualTo: chatId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      if(snapshot.docs.isEmpty){
        chatService.createChatIfNotExists(chatId, userId);
      }

      if (snapshot.docs.isNotEmpty) {
        var lastMsg = snapshot.docs.last;

        // Only mark as seen if message is from ADMIN
        if (lastMsg["senderId"] != userId && lastMsg["isSeen"] == false) {

          chatService.markMessagesAsSeen(chatId, userId);
        }
      }

      _scrollToBottom(isInitial: false);
    });
  }

  // 🔥 Improved Scroll Logic: Instant jump for entry, smooth for typing
  void _scrollToBottom({bool isInitial = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (isInitial) {
          // Instant jump - user doesn't see the top-to-bottom movement
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          // Smooth scroll for new messages
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }


  Future pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (file != null) {
      // 1. Upload and send the image message
      await chatService.sendImage(File(file.path), chatId, userId);

      // 2. Trigger notification for Admin
      await sendAdminNotification(
        senderRole: "customer",
        senderId: userId,
        sellerId: userId,
        title: "Support Request (Image)",
        body: "Sent a photo 📷",
        type: "message",
        category: "admin_support", // Useful for admin filtering
        actionId: chatId,         // So admin can click and open this specific chat
      );

      _scrollToBottom(isInitial: false);
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If Admin returns to the app, mark messages as seen
    if (state == AppLifecycleState.resumed) {
      chatService.markMessagesAsSeen(chatId, userId);
    }
  }
  // Shimmer skeleton
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: index % 2 == 0 ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              width: 150, height: 50,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(15)),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    double viewInset = MediaQuery.of(context).viewInsets.bottom;

    if (viewInset != _lastViewInset) {
      _lastViewInset = viewInset;

      if (viewInset > 0) {
        // keyboard opened
        _scrollToBottom(isInitial: false);
      }
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Customer Support", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatService.messages(chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingSkeleton();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet. Say Hi!"));
                }

                var msgs = snapshot.data!.docs;
                final lastMsg = msgs.last;
                if (lastMsg['senderId'] != userId && lastMsg['isSeen'] == false) {
                  chatService.markMessagesAsSeen(chatId, userId);
                }
                // 🔥 HANDLE SCREEN ENTRY VS UPDATES
                if (_isFirstLoad) {
                  _scrollToBottom(isInitial: true); // Instant jump
                  _isFirstLoad = false;
                } else {
                  _scrollToBottom(isInitial: false); // Smooth scroll for new msgs
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    var msg = msgs[index];
                    bool isMine = msg["senderId"] == userId;
                    bool isSeen = msg["isSeen"] ?? false;

                    return TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 400),
                      tween: Tween<double>(begin: 0, end: 1),
                      curve: Curves.easeOutBack,
                      builder: (context, double value, child) {
                        return Opacity(
                          opacity: value.clamp(0.0, 1.0), // No crash fix
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _buildMessageBubble(msg, isMine, isSeen),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  // _buildMessageBubble and _buildInputBar remain exactly as before,
  // just ensure _buildInputBar calls _scrollToBottom(isInitial: false) on send/tap.

  Widget _buildMessageBubble(DocumentSnapshot msg, bool isMine, bool isSeen) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 2, top: 8),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMine ? Colors.green : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: Radius.circular(isMine ? 15 : 2),
                bottomRight: Radius.circular(isMine ? 2 : 15),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            padding: msg["type"] == "image" ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg["type"] == "text")
                  Text(msg["message"] ?? "", style: TextStyle(color: isMine ? Colors.white : Colors.black87, fontSize: 15)),
                if (msg["type"] == "image")
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 100, maxHeight: 300, minWidth: 150),
                      child: Image.network(msg["imageUrl"], fit: BoxFit.cover),
                    ),
                  ),
              ],
            ),
          ),
          if (isMine)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 4),
              child: Icon(isSeen ? Icons.done_all : Icons.done, size: 14, color: isSeen ? Colors.blue : Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: SafeArea(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: IconButton(icon: const Icon(Icons.add, color: Colors.green), onPressed: pickImage),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(25)),
                child: TextField(
                  controller: controller,
                  onTap: () => _scrollToBottom(isInitial: false),
                  decoration: const InputDecoration(hintText: "Ask us anything...", contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.green, size: 28),
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                String text = controller.text.trim();
                controller.clear();
                await chatService.sendText(text, chatId, userId);
                await sendAdminNotification(
                  sellerId: userId,
                  senderRole: "admin",
                  senderId: userId,
                  title: "New Message from Customer",
                  body: text,
                  type: "message",
                  category: "admin_support",
                  actionId: chatId,
                );
                _scrollToBottom(isInitial: false);
              },
            ),
          ],
        ),
      ),
    );
  }
}