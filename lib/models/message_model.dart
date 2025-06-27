class MessageModel {
  final String id;
  final String senderId;
  final String senderPhoneNumber;
  final String senderName;
  final String? recipientId;
  final String? recipientPhoneNumber;
  final String content;
  final DateTime timestamp;
  final bool isGroupMessage;
  final String? propertyId;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderPhoneNumber,
    required this.senderName,
    this.recipientId,
    this.recipientPhoneNumber,
    required this.content,
    required this.timestamp,
    this.isGroupMessage = false,
    this.propertyId,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderPhoneNumber: json['senderPhoneNumber']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? json['senderPhoneNumber']?.toString() ?? 'Unknown User',
      recipientId: json['recipientId']?.toString(),
      recipientPhoneNumber: json['recipientPhoneNumber']?.toString(),
      content: json['content']?.toString() ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
      isGroupMessage: json['isGroupMessage'] ?? false,
      propertyId: json['propertyId']?.toString(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderId': senderId,
      'senderPhoneNumber': senderPhoneNumber,
      'senderName': senderName,
      'recipientId': recipientId,
      'recipientPhoneNumber': recipientPhoneNumber,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isGroupMessage': isGroupMessage,
      'propertyId': propertyId,
      'isRead': isRead,
    };
  }
}