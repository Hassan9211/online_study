import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_parsing.dart';
import '../../auth/repositories/local_auth_session_repository.dart';
import '../models/message_center_models.dart';
import 'local_message_center_repository.dart';
import 'message_center_repository.dart';

class RemoteMessageCenterRepository implements MessageCenterRepository {
  RemoteMessageCenterRepository(
    this._apiClient,
    this._localStore,
    this._authStore,
  );

  final ApiClient _apiClient;
  final LocalMessageCenterRepository _localStore;
  final LocalAuthSessionRepository _authStore;

  static const List<Color> _accentPalette = <Color>[
    Color(0xFFE5EAFF),
    Color(0xFFD8FAF0),
    Color(0xFFFFE4EB),
    Color(0xFFDDF8EF),
  ];

  @override
  Future<MessageCenterState> loadState() async {
    final cachedState = await _localStore.loadState();
    if (!await _hasAccessToken()) {
      return cachedState;
    }

    try {
      final conversationsBody = await _apiClient.getJson(
        ApiEndpoints.messages.conversations,
      );
      final notificationsBody = await _apiClient.getJson(
        ApiEndpoints.notifications.list,
      );

      final conversations = _parseConversations(conversationsBody);
      final notifications = _parseNotifications(notificationsBody);
      final aiGuestConversation = _findAiGuestConversation(conversations);
      final aiGuestMessages = aiGuestConversation == null
          ? cachedState.aiGuestMessages
          : await _loadConversationMessages(aiGuestConversation.id);

      final remoteState = MessageCenterState(
        conversations: conversations.isEmpty
            ? cachedState.conversations
            : conversations,
        aiGuestMessages: aiGuestMessages,
        notifications: notifications.isEmpty
            ? cachedState.notifications
            : notifications,
        nextNotificationId: _nextIdSeed(
          notifications.map((item) => item.id),
          fallback: cachedState.nextNotificationId,
        ),
        nextMessageId: _nextIdSeed(
          aiGuestMessages.map((item) => item.id),
          fallback: cachedState.nextMessageId,
        ),
      );
      await _localStore.saveState(remoteState);
      return remoteState;
    } catch (_) {
      return cachedState;
    }
  }

  @override
  Future<void> saveState(MessageCenterState state) {
    return _localStore.saveState(state);
  }

  @override
  Future<String> getAiGuestReply(String prompt) async {
    if (!await _hasAccessToken()) {
      return _localStore.getAiGuestReply(prompt);
    }

    try {
      final body = await _apiClient.postJson(
        ApiEndpoints.messages.aiGuestChat,
        body: <String, dynamic>{
          'message': prompt,
          'prompt': prompt,
        },
      );

      final reply = _extractReply(body);
      if (reply.isNotEmpty) {
        return reply;
      }
    } catch (_) {
      // Fall back to local deterministic responses.
    }

    return _localStore.getAiGuestReply(prompt);
  }

  @override
  Future<void> markNotificationsRead({List<String>? ids}) async {
    if (!await _hasAccessToken()) {
      return _localStore.markNotificationsRead(ids: ids);
    }

    try {
      final body = ids == null
          ? <String, dynamic>{}
          : <String, dynamic>{'ids': ids};
      await _apiClient.postJson(ApiEndpoints.notifications.read, body: body);
    } catch (_) {
      // Local cache should still be updated for UX continuity.
    }

    await _localStore.markNotificationsRead(ids: ids);
  }

  Future<bool> _hasAccessToken() async {
    final session = await _authStore.loadSession();
    return session.accessToken.trim().isNotEmpty;
  }

  List<MessageConversation> _parseConversations(dynamic body) {
    final payload = unwrapBody(body, keys: const ['data', 'conversations']);
    final list = payload is List
        ? payload
        : readList(asMap(body), const ['conversations', 'data']);

    return list.asMap().entries.map((entry) {
      final map = asMap(entry.value);
      final name = readString(
        map,
        const ['name', 'title'],
        fallback: 'Conversation',
      );
      final isOnline = readBool(
        map,
        const ['is_online', 'isOnline'],
        fallback: false,
      );
      final isAiGuest = readBool(
        map,
        const ['is_ai_guest', 'isAiGuest'],
        fallback:
            readString(map, const ['type']).toLowerCase().contains('ai') ||
            name.toLowerCase().contains('ai guest'),
      );

      return MessageConversation(
        id: readString(map, const ['id', 'conversation_id']),
        name: name,
        status: readString(
          map,
          const ['status', 'subtitle', 'description'],
          fallback: isOnline ? 'Online' : (isAiGuest ? 'AI assistant' : 'Offline'),
        ),
        preview: readString(
          map,
          const ['preview', 'last_message', 'message', 'body'],
          fallback: '',
        ),
        timestamp: readDateTime(
              map,
              const ['updated_at', 'last_message_at', 'timestamp', 'created_at'],
            ) ??
            DateTime.now(),
        accentColor: _accentPalette[entry.key % _accentPalette.length],
        isOnline: isOnline || isAiGuest,
        isAiGuest: isAiGuest,
        showMediaPreview: readBool(
          map,
          const ['show_media_preview', 'showMediaPreview'],
        ),
      );
    }).toList();
  }

  List<AppNotificationItem> _parseNotifications(dynamic body) {
    final payload = unwrapBody(body, keys: const ['data', 'notifications']);
    final list = payload is List
        ? payload
        : readList(asMap(body), const ['notifications', 'data']);

    return list.map((item) {
      final map = asMap(item);
      return AppNotificationItem(
        id: readString(map, const ['id', 'notification_id']),
        title: readString(map, const ['title'], fallback: 'Notification'),
        message: readString(
          map,
          const ['message', 'body'],
          fallback: '',
        ),
        type: _parseNotificationType(
          readString(map, const ['type'], fallback: NotificationType.update.name),
        ),
        timestamp: readDateTime(
              map,
              const ['timestamp', 'created_at', 'updated_at'],
            ) ??
            DateTime.now(),
        isRead: readBool(
          map,
          const ['is_read', 'isRead', 'read_at'],
          fallback: false,
        ),
      );
    }).toList();
  }

  Future<List<SupportChatMessage>> _loadConversationMessages(
    String conversationId,
  ) async {
    try {
      final body = await _apiClient.getJson(
        ApiEndpoints.messages.detail(conversationId),
      );
      final root = asMap(body);
      final payload = unwrapBody(body, keys: const ['data', 'conversation']);
      final messagesPayload = payload is Map
          ? readList(asMap(payload), const ['messages'])
          : payload;
      final list = messagesPayload is List
          ? messagesPayload
          : readList(root, const ['messages', 'data']);

      return list.map((item) {
        final map = asMap(item);
        final sender = readString(
          map,
          const ['sender_type', 'senderType', 'role'],
          fallback: MessageSenderType.user.name,
        );

        return SupportChatMessage(
          id: readString(map, const ['id', 'message_id']),
          text: readString(
            map,
            const ['text', 'message', 'body', 'content'],
            fallback: '',
          ),
          senderType: sender.toLowerCase().contains('assistant') ||
                  sender.toLowerCase().contains('ai')
              ? MessageSenderType.assistant
              : MessageSenderType.user,
          timestamp: readDateTime(
                map,
                const ['timestamp', 'created_at', 'updated_at'],
              ) ??
              DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return (await _localStore.loadState()).aiGuestMessages;
    }
  }

  MessageConversation? _findAiGuestConversation(
    List<MessageConversation> conversations,
  ) {
    for (final conversation in conversations) {
      if (conversation.isAiGuest) {
        return conversation;
      }
    }
    return null;
  }

  String _extractReply(dynamic body) {
    final root = asMap(body);
    final directReply = readString(
      root,
      const ['reply', 'response', 'message', 'text'],
    );
    if (directReply.isNotEmpty) {
      return directReply;
    }

    final data = asMap(unwrapBody(body, keys: const ['data', 'result']));
    final assistant = readMap(data, const ['assistant', 'message']);
    final assistantReply = readString(
      assistant,
      const ['text', 'message', 'body', 'content'],
    );
    if (assistantReply.isNotEmpty) {
      return assistantReply;
    }

    final messages = readList(data, const ['messages']);
    for (final item in messages.reversed) {
      final map = asMap(item);
      final sender = readString(map, const ['sender_type', 'role']);
      if (sender.toLowerCase().contains('assistant') ||
          sender.toLowerCase().contains('ai')) {
        return readString(
          map,
          const ['text', 'message', 'body', 'content'],
        );
      }
    }

    return '';
  }

  NotificationType _parseNotificationType(String rawType) {
    final normalized = rawType.trim().toLowerCase();
    for (final type in NotificationType.values) {
      if (type.name == normalized) {
        return type;
      }
    }
    if (normalized.contains('purchase')) {
      return NotificationType.purchase;
    }
    if (normalized.contains('message') || normalized.contains('chat')) {
      return NotificationType.message;
    }
    if (normalized.contains('reminder')) {
      return NotificationType.reminder;
    }
    if (normalized.contains('security') || normalized.contains('password')) {
      return NotificationType.security;
    }
    if (normalized.contains('celebr')) {
      return NotificationType.celebration;
    }
    return NotificationType.update;
  }

  int _nextIdSeed(Iterable<String> ids, {required int fallback}) {
    var maxValue = 0;
    for (final id in ids) {
      final match = RegExp(r'(\d+)$').firstMatch(id);
      final parsed = match == null ? null : int.tryParse(match.group(1)!);
      if (parsed != null && parsed > maxValue) {
        maxValue = parsed;
      }
    }

    return maxValue == 0 ? fallback : maxValue + 1;
  }
}
