import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zrai_mart/app_colors.dart';
import '../../../Notification/send_notification.dart';
import 'AdminChatService.dart';

class AdminChatScreen extends StatefulWidget {
  final String userId;
  const AdminChatScreen({super.key, required this.userId});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final AdminChatService chatService = AdminChatService();
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late String chatId;
  final String adminId = "admin";


  @override
  void initState() {
    super.initState();
    chatId = "${widget.userId}_admin";

    try{
      chatService.markMessagesAsSeen(chatId, adminId);

    } catch(e){
      debugPrint(e.toString());
    }
    // Initial check when opening the screen

    FirebaseFirestore.instance
        .collection("messages")
        .where("chatId", isEqualTo: chatId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      if(snapshot.docs.isEmpty){
        chatService.createChatIfNotExists(chatId, widget.userId);

      }

      if (snapshot.docs.isNotEmpty) {
        var lastMsg = snapshot.docs.last;

        // Only mark as seen if message is from USER and not already seen
        if (lastMsg["senderId"] != adminId && lastMsg["isSeen"] == false) {
          chatService.markMessagesAsSeen(chatId, adminId);
        }
      }

      _scrollToBottom();
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If Admin returns to the app, mark messages as seen
    if (state == AppLifecycleState.resumed) {
      chatService.markMessagesAsSeen(chatId, adminId);
    }
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
      await chatService.sendImage(File(file.path), chatId, adminId);
      _scrollToBottom();
    }
  }

  // Initial loading state skeleton
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Align(
          alignment: index % 2 == 0 ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.primaryGreen,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text("Support Thread", style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
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
                bool _isFirstLoad = true;
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                var msgs = snapshot.data!.docs;
                final lastMsg = msgs.last;
                if (lastMsg['senderId'] != adminId && lastMsg['isSeen'] == false) {
                  chatService.markMessagesAsSeen(chatId, adminId);
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    var msg = msgs[index];
                    bool isMine = msg["senderId"] == adminId;
                    bool isSeen = msg["isSeen"] ?? false;

                    return TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 400),
                      tween: Tween<double>(begin: 0, end: 1),
                      curve: Curves.easeOutBack,
                      builder: (context, double value, child) {
                        return Opacity(
                          opacity: value.clamp(0.0, 1.0), // FIX: Prevents assertion crash
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _buildChatBubble(msg, isMine, isSeen),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(DocumentSnapshot msg, bool isMine, bool isSeen) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 2, top: 8, left: 8, right: 8),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMine ? AppColors.primaryGreen : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMine ? 16 : 2),
                bottomRight: Radius.circular(isMine ? 2 : 16),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
              ],
            ),
            padding: msg["type"] == "image"
                ? const EdgeInsets.all(4)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg["type"] == "text")
                  Text(
                    msg["message"] ?? "",
                    style: TextStyle(color: isMine ? Colors.white : Colors.black87, fontSize: 15),
                  ),
                if (msg["type"] == "image")
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 100, maxHeight: 300, minWidth: 150),
                      child: Image.network(
                        msg["imageUrl"],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200, width: 200, color: Colors.grey.shade200,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isMine)
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 4),
              child: Icon(
                isSeen ? Icons.done_all : Icons.done,
                size: 14,
                color: isSeen ? Colors.blueAccent : Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: Icon(Icons.add_photo_alternate, color: AppColors.primaryGreen), onPressed: pickImage),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  onTap: _scrollToBottom,
                  decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.primaryGreen,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;
                  String text = controller.text.trim();
                  controller.clear();
                  await chatService.sendText(text, chatId, adminId,);

                  await sendNotification(
                    senderRole: "admin",
                    senderId: widget.userId,
                    sellerId: widget.userId,
                    userId: widget.userId,
                    title: "New Message from Support",
                    body: text,
                    type: "message",
                    category: "admin_support",
                    actionId: chatId,
                  );
                  _scrollToBottom();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}