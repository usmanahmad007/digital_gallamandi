import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'AdminChatScreen.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  // 🕒 FORMAT TIME
  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "";

    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();

    // Today → show time
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final isPM = hour >= 12;
      final formattedHour = hour % 12 == 0 ? 12 : hour % 12;

      return "$formattedHour:$minute ${isPM ? 'PM' : 'AM'}";
    }

    // Yesterday or older → show date
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "All Support Chats",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("adminChat")
            .orderBy("lastTime", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No support chats found."));
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final data =
                  chats[index].data() as Map<String, dynamic>? ?? {};

              List participants =
              (data["participants"] is List) ? data["participants"] : [];

              String userId = participants.firstWhere(
                    (e) => e != "admin",
                orElse: () => "unknown",
              );

              String lastMessage = data["lastMessage"] ?? "";
              String lastType = data["lastType"] ?? "text";
              Timestamp? lastTime = data["lastTime"] as Timestamp?;

              bool isSeen = data["isSeen"] ?? true;
              String lastSenderId = data["senderId"] ?? "";

              // 🔵 unread logic
              bool isUnread = lastSenderId != "admin" && isSeen == false;

              Widget subtitleWidget;

              if (lastType == "image") {
                subtitleWidget = const Row(
                  children: [
                    Icon(Icons.image, size: 16, color: Colors.grey),
                    SizedBox(width: 5),
                    Text("Photo", style: TextStyle(color: Colors.grey)),
                  ],
                );
              } else {
                subtitleWidget = Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                );
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("saller")
                    .doc(userId)
                    .get()
                    .then((sellerDoc) async {
                  if (sellerDoc.exists) {
                    return sellerDoc;
                  } else {
                    return FirebaseFirestore.instance
                        .collection("users")
                        .doc(userId)
                        .get();
                  }
                }),
                builder: (context, userSnap) {
                  if (userSnap.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFF5F5F5),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      title: Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      subtitle: Container(
                        width: 150,
                        height: 10,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }

                  String name = "User";
                  String image = "";

                  if (userSnap.hasData &&
                      userSnap.data!.exists) {
                    var userData =
                    userSnap.data!.data()
                    as Map<String, dynamic>;

                    name = userData["name"] ??
                        userData["username"] ??
                        userData["fullName"] ??
                        "User";

                    image = userData["image"] ??
                        userData["profileImage"] ??
                        "";
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      Colors.blue.withOpacity(0.1),
                      backgroundImage:
                      image.isNotEmpty ? NetworkImage(image) : null,
                      child: image.isEmpty
                          ? Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : "?",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    subtitle: Row(
                      children: [
                        // ✔ tick before message
                        Icon(
                          isSeen
                              ? Icons.done_all
                              : Icons.done,
                          size: 16,
                          color:
                          isSeen ? Colors.blue : Colors.grey,
                        ),

                        const SizedBox(width: 6),

                        // message
                        Expanded(child: subtitleWidget),

                        const SizedBox(width: 6),

                        // 🕒 time
                        Text(
                          _formatTime(lastTime),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(width: 6),

                        // 🔵 unread dot
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminChatScreen(userId: userId),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}