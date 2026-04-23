import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

class AdminChatService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  final String adminId = "admin";

  String chatId(String userId) => "${userId}_admin";

  // ================= CREATE CHAT =================
  Future createChatIfNotExists(String chatId, String userId) async {
    await firestore.collection("adminChat").doc(chatId).set({
      "participants": [userId, adminId],
      "lastMessage": "",
      "lastType": "text",
      "lastTime": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ================= SEND TEXT =================
  Future sendText(String text, String chatId, String senderId) async {
    await firestore.collection("messages").add({
      "chatId": chatId,
      "senderId": senderId,
      "type": "text",
      "message": text,
      "timestamp": FieldValue.serverTimestamp(),

      // ⭐ IMPORTANT
      "isSeen": false,
    });

    debugPrint("GIFT1");
    await firestore.collection("adminChat").doc(chatId).set({
      "lastMessage": text,
      "lastType": "text",
      "lastTime": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    debugPrint("GIFT2");

  }

  // ================= SEND IMAGE =================
  Future sendImage(File file, String chatId, String senderId) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    Reference ref = storage.ref().child("chat/$fileName.jpg");

    await ref.putFile(file);
    String url = await ref.getDownloadURL();

    await firestore.collection("messages").add({
      "chatId": chatId,
      "senderId": senderId,
      "type": "image",
      "imageUrl": url,
      "timestamp": FieldValue.serverTimestamp(),

      // ⭐ IMPORTANT
      "isSeen": false,
    });

    await firestore.collection("adminChat").doc(chatId).set({
      "lastMessage": "📷 Image",
      "lastType": "image",
      "lastTime": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ================= STREAM MESSAGES =================
  Stream<QuerySnapshot> messages(String chatId) {
    return firestore
        .collection("messages")
        .where("chatId", isEqualTo: chatId)
        .orderBy("timestamp")
        .snapshots();
  }

  // ================= MARK AS SEEN (IMPORTANT FIX) =================
  // ================= MARK AS SEEN (CORRECTED) =================
  Future markMessagesAsSeen(String chatId, String viewerId) async {
    try {
      // Find all messages in this chat NOT sent by the viewer that are UNREAD
      final QuerySnapshot snapshot = await firestore
          .collection("messages")
          .where("chatId", isEqualTo: chatId)
          .where("senderId", isNotEqualTo: viewerId)
          .where("isSeen", isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final WriteBatch batch = firestore.batch();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {"isSeen": true});
      }

      // Submit all updates in one single trip to the server
      await batch.commit();
    } catch (e) {
      debugPrint("Error marking as seen: $e");
    }
  }
}
