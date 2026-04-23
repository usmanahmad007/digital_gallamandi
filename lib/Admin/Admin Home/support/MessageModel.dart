class MessageModel {
  String senderId;
  String message;
  String type;
  String imageUrl;
  DateTime timestamp;
  bool seen;

  MessageModel({
    required this.senderId,
    required this.message,
    required this.type,
    required this.imageUrl,
    required this.timestamp,
    required this.seen,
  });

  Map<String, dynamic> toMap() {
    return {
      "senderId": senderId,
      "message": message,
      "type": type,
      "imageUrl": imageUrl,
      "timestamp": timestamp,
      "seen": seen
    };
  }
}