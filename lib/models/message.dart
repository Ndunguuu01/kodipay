import 'package:flutter/material.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final bool isGroupMessage;
  final String? propertyId;
  final MessageStatus status;
  final MessageCategory category;
  final List<String>? attachments;
  final String? replyToId;
  final String? replyToContent;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.isGroupMessage = false,
    this.propertyId,
    this.status = MessageStatus.sent,
    this.category = MessageCategory.normal,
    this.attachments,
    this.replyToId,
    this.replyToContent,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      isGroupMessage: json['isGroupMessage'] ?? false,
      propertyId: json['propertyId'],
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      category: MessageCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => MessageCategory.normal,
      ),
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
      replyToId: json['replyToId'],
      replyToContent: json['replyToContent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isGroupMessage': isGroupMessage,
      'propertyId': propertyId,
      'status': status.toString().split('.').last,
      'category': category.toString().split('.').last,
      'attachments': attachments,
      'replyToId': replyToId,
      'replyToContent': replyToContent,
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    bool? isGroupMessage,
    String? propertyId,
    MessageStatus? status,
    MessageCategory? category,
    List<String>? attachments,
    String? replyToId,
    String? replyToContent,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isGroupMessage: isGroupMessage ?? this.isGroupMessage,
      propertyId: propertyId ?? this.propertyId,
      status: status ?? this.status,
      category: category ?? this.category,
      attachments: attachments ?? this.attachments,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
    );
  }
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  String get displayName {
    switch (this) {
      case MessageStatus.sending:
        return 'Sending...';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
      case MessageStatus.failed:
        return 'Failed to send';
    }
  }

  IconData get icon {
    switch (this) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
    }
  }

  Color get color {
    switch (this) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.grey;
      case MessageStatus.read:
        return Colors.blue;
      case MessageStatus.failed:
        return Colors.red;
    }
  }
}

enum MessageCategory {
  normal,
  important,
  urgent,
  announcement;

  String get displayName {
    switch (this) {
      case MessageCategory.normal:
        return 'Normal';
      case MessageCategory.important:
        return 'Important';
      case MessageCategory.urgent:
        return 'Urgent';
      case MessageCategory.announcement:
        return 'Announcement';
    }
  }

  Color get color {
    switch (this) {
      case MessageCategory.normal:
        return Colors.grey;
      case MessageCategory.important:
        return Colors.orange;
      case MessageCategory.urgent:
        return Colors.red;
      case MessageCategory.announcement:
        return Colors.blue;
    }
  }

  IconData get icon {
    switch (this) {
      case MessageCategory.normal:
        return Icons.message;
      case MessageCategory.important:
        return Icons.priority_high;
      case MessageCategory.urgent:
        return Icons.warning;
      case MessageCategory.announcement:
        return Icons.announcement;
    }
  }
} 