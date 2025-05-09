class MessageModel {
  final String id;
  final String senderId;
  final String senderPhoneNumber;
  final String? recipientId;
  final String? recipientPhoneNumber;
  final String content;
  final DateTime timestamp;
  final bool isGroupMessage;
  final String? propertyId;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderPhoneNumber,
    this.recipientId,
    this.recipientPhoneNumber,
    required this.content,
    required this.timestamp,
    required this.isGroupMessage,
    this.propertyId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'],
      senderId: json['sender']['_id'],
      senderPhoneNumber: json['sender']['phoneNumber'],
      recipientId: json['recipient']?['_id'],
      recipientPhoneNumber: json['recipient']?['phoneNumber'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isGroupMessage: json['isGroupMessage'] ?? false,
      propertyId: json['propertyId'],
    );
  }

  toJson() {}
}