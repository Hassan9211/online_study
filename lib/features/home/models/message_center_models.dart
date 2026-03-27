import 'dart:convert';

import 'package:flutter/material.dart';

enum NotificationType {
  purchase,
  message,
  update,
  celebration,
  reminder,
  security,
}

enum MessageSenderType { user, assistant }

class MessageConversation {
  const MessageConversation({
    required this.id,
    required this.name,
    required this.status,
    required this.preview,
    required this.timestamp,
    required this.accentColor,
    required this.isOnline,
    this.isAiGuest = false,
    this.showMediaPreview = false,
  });

  final String id;
  final String name;
  final String status;
  final String preview;
  final DateTime timestamp;
  final bool isOnline;
  final bool isAiGuest;
  final bool showMediaPreview;
  final Color accentColor;

  MessageConversation copyWith({String? preview, DateTime? timestamp}) {
    return MessageConversation(
      id: id,
      name: name,
      status: status,
      preview: preview ?? this.preview,
      timestamp: timestamp ?? this.timestamp,
      accentColor: accentColor,
      isOnline: isOnline,
      isAiGuest: isAiGuest,
      showMediaPreview: showMediaPreview,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'status': status,
      'preview': preview,
      'timestamp': timestamp.toIso8601String(),
      'isOnline': isOnline,
      'isAiGuest': isAiGuest,
      'showMediaPreview': showMediaPreview,
      'accentColor': accentColor.toARGB32(),
    };
  }

  factory MessageConversation.fromMap(Map<String, dynamic> map) {
    return MessageConversation(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      status: map['status'] as String? ?? '',
      preview: map['preview'] as String? ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      isOnline: map['isOnline'] as bool? ?? false,
      isAiGuest: map['isAiGuest'] as bool? ?? false,
      showMediaPreview: map['showMediaPreview'] as bool? ?? false,
      accentColor: Color(map['accentColor'] as int? ?? 0xFFE5EAFF),
    );
  }
}

class SupportChatMessage {
  const SupportChatMessage({
    required this.id,
    required this.text,
    required this.senderType,
    required this.timestamp,
  });

  final String id;
  final String text;
  final MessageSenderType senderType;
  final DateTime timestamp;

  bool get isUser => senderType == MessageSenderType.user;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'senderType': senderType.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SupportChatMessage.fromMap(Map<String, dynamic> map) {
    final senderName = map['senderType'] as String? ?? MessageSenderType.user.name;
    return SupportChatMessage(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      senderType: MessageSenderType.values.firstWhere(
        (type) => type.name == senderName,
        orElse: () => MessageSenderType.user,
      ),
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;

  AppNotificationItem copyWith({bool? isRead}) {
    return AppNotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotificationItem.fromMap(Map<String, dynamic> map) {
    final typeName = map['type'] as String? ?? NotificationType.update.name;
    return AppNotificationItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (value) => value.name == typeName,
        orElse: () => NotificationType.update,
      ),
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }
}

class MessageCenterState {
  const MessageCenterState({
    required this.conversations,
    required this.aiGuestMessages,
    required this.notifications,
    required this.nextNotificationId,
    required this.nextMessageId,
  });

  final List<MessageConversation> conversations;
  final List<SupportChatMessage> aiGuestMessages;
  final List<AppNotificationItem> notifications;
  final int nextNotificationId;
  final int nextMessageId;

  MessageCenterState copyWith({
    List<MessageConversation>? conversations,
    List<SupportChatMessage>? aiGuestMessages,
    List<AppNotificationItem>? notifications,
    int? nextNotificationId,
    int? nextMessageId,
  }) {
    return MessageCenterState(
      conversations: conversations ?? this.conversations,
      aiGuestMessages: aiGuestMessages ?? this.aiGuestMessages,
      notifications: notifications ?? this.notifications,
      nextNotificationId: nextNotificationId ?? this.nextNotificationId,
      nextMessageId: nextMessageId ?? this.nextMessageId,
    );
  }

  String toJson() {
    return jsonEncode(<String, dynamic>{
      'conversations': conversations.map((item) => item.toMap()).toList(),
      'aiGuestMessages': aiGuestMessages.map((item) => item.toMap()).toList(),
      'notifications': notifications.map((item) => item.toMap()).toList(),
      'nextNotificationId': nextNotificationId,
      'nextMessageId': nextMessageId,
    });
  }

  factory MessageCenterState.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return MessageCenterState(
      conversations: (map['conversations'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => MessageConversation.fromMap(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      aiGuestMessages: (map['aiGuestMessages'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => SupportChatMessage.fromMap(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      notifications: (map['notifications'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => AppNotificationItem.fromMap(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      nextNotificationId: map['nextNotificationId'] as int? ?? 1,
      nextMessageId: map['nextMessageId'] as int? ?? 1,
    );
  }
}
