import 'dart:async';

import 'package:get/get.dart';

import '../models/message_center_models.dart';
import '../repositories/message_center_repository.dart';

export '../models/message_center_models.dart';

class MessageCenterController extends GetxController {
  MessageCenterController(this._repository);

  final MessageCenterRepository _repository;

  Timer? _clockTimer;

  bool _isAiGuestTyping = false;
  int _notificationIdSeed = 1;
  int _messageIdSeed = 1;

  List<MessageConversation> _conversations = <MessageConversation>[];
  List<SupportChatMessage> _aiGuestMessages = <SupportChatMessage>[];
  List<AppNotificationItem> _notifications = <AppNotificationItem>[];

  List<MessageConversation> get conversations =>
      List<MessageConversation>.unmodifiable(_conversations);
  List<SupportChatMessage> get aiGuestMessages =>
      List<SupportChatMessage>.unmodifiable(_aiGuestMessages);
  List<AppNotificationItem> get notifications =>
      List<AppNotificationItem>.unmodifiable(_notifications);
  bool get isAiGuestTyping => _isAiGuestTyping;

  bool get hasUnreadNotifications =>
      _notifications.any((notification) => !notification.isRead);

  @override
  void onInit() {
    super.onInit();
    _loadState();
    _clockTimer = Timer.periodic(const Duration(seconds: 15), (_) => update());
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    super.onClose();
  }

  Future<void> markNotificationsSeen() async {
    if (!hasUnreadNotifications) {
      return;
    }

    _notifications = _notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
    await _persistState();
    await _repository.markNotificationsRead();
    update();
  }

  Future<void> addNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.update,
  }) async {
    _notifications.insert(
      0,
      _createNotification(
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
      ),
    );

    if (_notifications.length > 18) {
      _notifications.removeLast();
    }

    await _persistState();
    update();
  }

  Future<void> recordPurchaseSuccess() async {
    await addNotification(
      title: 'Successful purchase!',
      message: 'Your course has been unlocked and is ready to play.',
      type: NotificationType.purchase,
    );
  }

  Future<void> recordProfileUpdated() async {
    await addNotification(
      title: 'Profile updated',
      message: 'Your name and account details were saved successfully.',
      type: NotificationType.update,
    );
  }

  Future<void> recordProfilePhotoUpdated() async {
    await addNotification(
      title: 'Profile photo updated',
      message: 'Your new profile picture is now visible across the app.',
      type: NotificationType.update,
    );
  }

  Future<void> recordPasswordChanged() async {
    await addNotification(
      title: 'Password changed',
      message: 'Your account password was updated just now.',
      type: NotificationType.security,
    );
  }

  Future<void> sendAiGuestMessage(String text) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty || _isAiGuestTyping) {
      return;
    }

    _aiGuestMessages.add(
      SupportChatMessage(
        id: 'message_${_messageIdSeed++}',
        text: normalizedText,
        senderType: MessageSenderType.user,
        timestamp: DateTime.now(),
      ),
    );
    _updateConversationPreview(
      preview: normalizedText,
      timestamp: DateTime.now(),
    );
    await _persistState();
    update();

    _isAiGuestTyping = true;
    update();

    await Future<void>.delayed(const Duration(milliseconds: 900));

    try {
      final reply = await _repository.getAiGuestReply(normalizedText);
      _aiGuestMessages.add(
        SupportChatMessage(
          id: 'message_${_messageIdSeed++}',
          text: reply,
          senderType: MessageSenderType.assistant,
          timestamp: DateTime.now(),
        ),
      );
      final replyTimestamp = DateTime.now();
      _updateConversationPreview(
        preview: reply,
        timestamp: replyTimestamp,
      );
      _isAiGuestTyping = false;
      await addNotification(
        title: 'New message from AI Guest',
        message: reply,
        type: NotificationType.message,
      );
      update();
    } catch (_) {
      _isAiGuestTyping = false;
      update();
    }
  }

  String conversationTimeLabel(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inHours < 24) {
      final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final suffix = timestamp.hour >= 12 ? 'pm' : 'am';
      return '$hour:$minute $suffix';
    }

    return 'Yesterday';
  }

  String notificationTimeLabel(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    return '${difference.inDays}d ago';
  }

  AppNotificationItem _createNotification({
    required String title,
    required String message,
    required NotificationType type,
    required DateTime timestamp,
  }) {
    return AppNotificationItem(
      id: 'notification_${_notificationIdSeed++}',
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: false,
    );
  }

  void _updateConversationPreview({
    required String preview,
    required DateTime timestamp,
  }) {
    final aiGuestIndex = _conversations.indexWhere(
      (conversation) => conversation.id == 'ai_guest',
    );
    if (aiGuestIndex == -1) {
      return;
    }

    final updatedConversation = _conversations[aiGuestIndex].copyWith(
      preview: preview,
      timestamp: timestamp,
    );
    _conversations[aiGuestIndex] = updatedConversation;
    _conversations.sort(
      (first, second) => second.timestamp.compareTo(first.timestamp),
    );
  }

  Future<void> _loadState() async {
    final state = await _repository.loadState();
    _conversations = List<MessageConversation>.from(state.conversations)
      ..sort((first, second) => second.timestamp.compareTo(first.timestamp));
    _aiGuestMessages = List<SupportChatMessage>.from(state.aiGuestMessages)
      ..sort((first, second) => first.timestamp.compareTo(second.timestamp));
    _notifications = List<AppNotificationItem>.from(state.notifications)
      ..sort((first, second) => second.timestamp.compareTo(first.timestamp));
    _notificationIdSeed = state.nextNotificationId;
    _messageIdSeed = state.nextMessageId;
    update();
  }

  Future<void> _persistState() async {
    await _repository.saveState(
      MessageCenterState(
        conversations: _conversations,
        aiGuestMessages: _aiGuestMessages,
        notifications: _notifications,
        nextNotificationId: _notificationIdSeed,
        nextMessageId: _messageIdSeed,
      ),
    );
  }

  Future<void> refreshState() async {
    await _loadState();
  }
}
