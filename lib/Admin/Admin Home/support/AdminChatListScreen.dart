import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'AdminChatScreen.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Support Chats")),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("adminChat")
            .orderBy("lastTime", descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {

              final data = chats[index].data() as Map<String, dynamic>? ?? {};
              final chatId = chats[index].id;

              // ================= SAFE PARTICIPANTS =================
              List participants =
              (data["participants"] is List) ? data["participants"] : [];

              String userId = participants.firstWhere(
                    (e) => e != "admin",
                orElse: () => "unknown",
              );

              // ================= LAST MESSAGE =================
              String lastMessage = data["lastMessage"] ?? "";
              String lastType = data["lastType"] ?? "text";

              Timestamp? lastTime = data["lastTime"] as Timestamp?;
              Timestamp? lastSeenAdmin =
              (data["lastSeen"]?["admin"]) as Timestamp?;

              // ================= UNREAD LOGIC =================
              bool hasUnread = false;

              if (lastTime != null) {
                if (lastSeenAdmin == null) {
                  hasUnread = true;
                } else {
                  hasUnread = lastTime.millisecondsSinceEpoch >
                      lastSeenAdmin.millisecondsSinceEpoch;
                }
              }

              // ================= SUBTITLE =================
              // ================= SUBTITLE =================
              Widget subtitle;

              if (lastType == "image") {
                subtitle = const Row(
                  children: [
                    Icon(Icons.image, size: 16, color: Colors.grey),
                    SizedBox(width: 5),
                    Text("Photo"),
                  ],
                );
              } else {
                subtitle = Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                );
              }

              // ================= SEEN ICON =================
              Widget seenIcon = const Icon(
                Icons.done,
                size: 18,
                color: Colors.grey,
              );

              if (lastTime != null && lastSeenAdmin != null) {
                bool seen = lastSeenAdmin.toDate().isAfter(
                  lastTime.toDate(),
                );

                seenIcon = Icon(
                  seen ? Icons.done_all : Icons.done,
                  size: 18,
                  color: seen ? Colors.blue : Colors.grey,
                );
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("seller")
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

                  String name = userId;
                  String image = "";

                  if (userSnap.hasData && userSnap.data!.exists) {
                    var userData = userSnap.data!.data() as Map<String, dynamic>;

                    name = userData["name"] ??
                        userData["username"] ??
                        userData["fullName"] ??
                        userId;

                    image = userData["image"] ?? userData["profileImage"] ?? "";
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                      child: image.isEmpty
                          ? Text(
                        name.length >= 2
                            ? name.substring(0, 2).toUpperCase()
                            : "D",
                      )
                          : null,
                    ),


                    title: Text(name),

                    subtitle: Row(
                      children: [
                        Expanded(child: subtitle),
                        const SizedBox(width: 6),
                        seenIcon,
                      ],
                    ),

                    trailing: hasUnread
                        ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    )
                        : const SizedBox(),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminChatScreen(userId: userId),
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