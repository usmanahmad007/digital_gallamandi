import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

Future<void> sendNotification({
  required String senderRole, // customer | seller | admin
  required String senderId,

  String? userId,
  String? sellerId,

  required String title,
  required String body,

  required String type,
  required String category,

  String? actionId,
}) async {

  try {

    debugPrint(senderRole);
    await FirebaseFirestore.instance.collection('notifications').add({

      "senderId": senderId,
      "senderRole": senderRole,

      "userId": userId,
      "sellerId": sellerId,
      "isAdmin": senderRole == "admin",

      "title": title,
      "body": body,

      "type": type,
      "category": category,
      "actionId": actionId ?? "",

      "userIsRead": false,
      "sellerIsRead": false,
      "adminIsRead": false,

      "timestamp": FieldValue.serverTimestamp(),
    });

  } catch (e) {
    debugPrint("Notification Error: $e");
  }
}
Future<void> sendAdminNotification({
  required String senderRole, // customer | seller | admin
  required String senderId,

  String? userId,
  String? sellerId,

  required String title,
  required String body,

  required String type,
  required String category,

  String? actionId,
}) async {

  try {

    debugPrint(senderRole);
    await FirebaseFirestore.instance.collection('AdminNotifications').add({

      "senderId": senderId,
      "senderRole": senderRole,

      "userId": userId,
      "sellerId": sellerId,
      "isAdmin": senderRole == "admin",

      "title": title,
      "body": body,

      "type": type,
      "category": category,
      "actionId": actionId ?? "",

      "userIsRead": false,
      "sellerIsRead": false,
      "adminIsRead": false,

      "timestamp": FieldValue.serverTimestamp(),
    });

  } catch (e) {
    debugPrint("Notification Error: $e");
  }
}