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
  static const String _aiGuestAppContext =
      'Online Study app context: onboarding, login, signup, OTP verification, Product Design v1.0 course, checkout with payment methods and payment password, lesson playback, course progress, my courses, favourites, notifications, AI guest chat, edit account, profile photo updates, settings and privacy, change password, and support requests.';
  static const String _aiGuestInstruction =
      'Answer specifically about the Online Study app. Use the user question directly, avoid repeating the previous answer when the question changes, and mention the relevant screen or next step when possible.';

  @override
  Future<MessageCenterState> loadCachedState() {
    return _localStore.loadState();
  }

  @override
  Future<MessageCenterState> loadState() async {
    final cachedState = await _localStore.loadState();
    if (!await _hasAccessToken()) {
      return cachedState;
    }

    try {
      final responses = await Future.wait<dynamic>(<Future<dynamic>>[
        _apiClient.getJson(ApiEndpoints.messages.conversations),
        _apiClient.getJson(ApiEndpoints.notifications.list),
      ]);
      final conversationsBody = responses[0];
      final notificationsBody = responses[1];

      final conversations = _parseConversations(conversationsBody);
      final notifications = _parseNotifications(notificationsBody);
      final aiGuestConversation = _findAiGuestConversation(conversations);
      final aiGuestMessages = aiGuestConversation == null
          ? cachedState.aiGuestMessages
          : await loadConversationMessages(aiGuestConversation.id);

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
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
      }
      return cachedState;
    } catch (_) {
      return cachedState;
    }
  }

  @override
  Future<void> saveState(MessageCenterState state) {
    return _localStore.saveState(state);
  }

  @override
  Future<void> clearCachedState() {
    return _localStore.clearCachedState();
  }

  @override
  Future<String> getAiGuestReply(String prompt) async {
    if (!ApiConfig.useRemoteAiGuest) {
      return _localStore.getAiGuestReply(prompt);
    }

    final recentHistory = await _recentAiGuestHistory();
    final lastAssistantReply = _lastAssistantReply(recentHistory);
    if (!await _hasAccessToken()) {
      return _localStore.getAiGuestReply(prompt);
    }

    try {
      final body = await _apiClient.postJson(
        ApiEndpoints.messages.aiGuestChat,
        body: <String, dynamic>{
          'message': prompt,
          'context': _aiGuestAppContext,
          'instruction': _aiGuestInstruction,
          'history': recentHistory,
        },
      );

      final reply = _extractReply(body);
      if (!_shouldUseLocalFallback(prompt, reply, lastAssistantReply)) {
        return reply;
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
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
      if (ids != null && ids.length == 1) {
        await _apiClient.postJson(ApiEndpoints.notifications.detailRead(ids.first));
      } else {
        final body = ids == null
            ? <String, dynamic>{}
            : <String, dynamic>{'ids': ids};
        await _apiClient.postJson(ApiEndpoints.notifications.read, body: body);
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
      }
    } catch (_) {
      // Local cache should still be updated for UX continuity.
    }

    await _localStore.markNotificationsRead(ids: ids);
  }

  @override
  Future<List<SupportChatMessage>> loadConversationMessages(
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

      final messages = list.map((item) {
        return _parseChatMessage(asMap(item));
      }).where((message) {
        return message.text.trim().isNotEmpty;
      }).toList();

      if (messages.isNotEmpty) {
        return messages;
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
      }
    } catch (_) {
      // Fall back to local seed content below.
    }

    return _localStore.loadConversationMessages(conversationId);
  }

  @override
  Future<SupportChatMessage> sendConversationMessage({
    required String conversationId,
    required String text,
  }) async {
    try {
      final body = await _apiClient.postJson(
        ApiEndpoints.messages.send(conversationId),
        body: <String, dynamic>{
          'message': text,
        },
      );
      final payload = asMap(unwrapBody(body, keys: const ['data', 'message']));
      final parsed = _parseChatMessage(
        payload.isEmpty ? asMap(body) : payload,
        fallbackText: text,
      );
      if (parsed.text.trim().isNotEmpty) {
        return parsed;
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _expireSession();
      }
    } catch (_) {
      // Use local optimistic message if the backend send fails.
    }

    return _localStore.sendConversationMessage(
      conversationId: conversationId,
      text: text,
    );
  }

  Future<bool> _hasAccessToken() async {
    final session = await _authStore.loadSession();
    return session.accessToken.trim().isNotEmpty;
  }

  Future<void> _expireSession() {
    return _authStore.invalidateSession();
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

  SupportChatMessage _parseChatMessage(
    Map<String, dynamic> map, {
    String fallbackText = '',
  }) {
    final sender = readString(
      map,
      const ['sender_type', 'senderType', 'role'],
      fallback: MessageSenderType.user.name,
    );

    return SupportChatMessage(
      id: readString(
        map,
        const ['id', 'message_id'],
        fallback: 'message_${DateTime.now().millisecondsSinceEpoch}',
      ),
      text: readString(
        map,
        const ['text', 'message', 'body', 'content'],
        fallback: fallbackText,
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
    final data = asMap(unwrapBody(body, keys: const ['data', 'result']));
    final dataReply = readString(
      data,
      const ['reply', 'response', 'message', 'text', 'content', 'answer', 'output'],
    );
    if (dataReply.isNotEmpty && !_isStatusMessage(dataReply)) {
      return dataReply;
    }

    final assistant = readMap(data, const ['assistant', 'message']);
    final assistantReply = readString(
      assistant,
      const ['text', 'message', 'body', 'content', 'answer'],
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
          const ['text', 'message', 'body', 'content', 'answer'],
        );
      }
    }

    final directReply = readString(
      root,
      const ['reply', 'response', 'message', 'text', 'answer', 'output'],
    );
    if (directReply.isNotEmpty && !_isStatusMessage(directReply)) {
      return directReply;
    }

    return '';
  }

  bool _isStatusMessage(String value) {
    final normalized = value.trim().toLowerCase();
    const genericMessages = <String>{
      'ok',
      'success',
      'request successful',
      'message received',
      'chat request received',
      'ai guest response generated',
    };

    if (genericMessages.contains(normalized)) {
      return true;
    }

    return normalized.startsWith('your request') ||
        normalized.startsWith('request ') ||
        normalized.startsWith('message ');
  }

  bool _shouldUseLocalFallback(
    String prompt,
    String reply,
    String lastAssistantReply,
  ) {
    final normalizedReply = reply.trim();
    if (normalizedReply.isEmpty) {
      return true;
    }

    final normalizedLowerReply = normalizedReply.toLowerCase();
    final normalizedPrompt = prompt.trim().toLowerCase();
    final normalizedLastAssistant = lastAssistantReply.trim().toLowerCase();

    if (_isStatusMessage(normalizedReply)) {
      return true;
    }

    if (normalizedLastAssistant.isNotEmpty &&
        normalizedLastAssistant == normalizedLowerReply &&
        !_isGreetingPrompt(normalizedPrompt)) {
      return true;
    }

    if (_isGenericReply(normalizedLowerReply) &&
        !_isGreetingPrompt(normalizedPrompt)) {
      return true;
    }

    return false;
  }

  bool _isGenericReply(String value) {
    const genericReplies = <String>{
      'hello, i am ai guest. how can i help you today?',
      'i can help with courses, notifications, payments, profile settings, and lessons. ask a more specific question and i will give a clearer answer.',
      'if your question is about a screen, course, payment, account feature, or support flow, i can guide you.',
      'you can ask me about course unlocks, playback, account updates, notifications, or support requests.',
    };

    if (genericReplies.contains(value)) {
      return true;
    }

    return value.startsWith('thanks for your question') ||
        value.contains('tie this back to the lesson objectives') ||
        value.contains('try a small exercise from the course') ||
        value.contains('revisit your notes after watching the related video') ||
        value.startsWith('how can i help') ||
        value.startsWith('please ask') ||
        value.startsWith('i can help with');
  }

  bool _isGreetingPrompt(String prompt) {
    return prompt.contains('hello') ||
        prompt.contains('hi') ||
        prompt.contains('hey') ||
        prompt.contains('salam') ||
        prompt.contains('assalam');
  }

  Future<List<Map<String, String>>> _recentAiGuestHistory() async {
    final state = await _localStore.loadState();
    final recentMessages = state.aiGuestMessages.length <= 8
        ? state.aiGuestMessages
        : state.aiGuestMessages.sublist(state.aiGuestMessages.length - 8);

    return recentMessages.map((message) {
      return <String, String>{
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      };
    }).toList();
  }

  String _lastAssistantReply(List<Map<String, String>> history) {
    for (final item in history.reversed) {
      if ((item['role'] ?? '') == 'assistant') {
        return item['content'] ?? '';
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

