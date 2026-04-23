import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  String chatId;
  List participants;
  String lastMessage;
  DateTime lastTime;

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastTime,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      chatId: id,
      participants: map['participants'],
      lastMessage: map['lastMessage'] ?? '',
      lastTime: (map['lastTime'] as Timestamp).toDate(),
    );
  }
}