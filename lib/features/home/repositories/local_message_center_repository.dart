import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message_center_models.dart';
import 'message_center_repository.dart';

class LocalMessageCenterRepository implements MessageCenterRepository {
  static const String _stateKey = 'message_center_state';
  static const String _aiGuestPreview =
      'Ask me anything about courses, videos, payments, or your account.';
  static const String _aiGuestWelcome =
      'Hello, I am AI Guest. You can ask me about courses, payments, profile settings, passwords, or videos.';

  final Random _random = Random();

  @override
  Future<MessageCenterState> loadCachedState() => loadState();

  @override
  Future<MessageCenterState> loadState() async {
    final preferences = await SharedPreferences.getInstance();
    final savedState = preferences.getString(_stateKey);

    if (savedState != null && savedState.isNotEmpty) {
      final restoredState = _normalizeState(MessageCenterState.fromJson(savedState));
      await saveState(restoredState);
      return restoredState;
    }

    final now = DateTime.now();
    final seededState = MessageCenterState(
      conversations: <MessageConversation>[
        MessageConversation(
          id: 'ai_guest',
          name: 'AI Guest',
          status: 'AI assistant',
          preview: _aiGuestPreview,
          timestamp: now.subtract(const Duration(minutes: 1)),
          accentColor: const Color(0xFFE5EAFF),
          isOnline: true,
          isAiGuest: true,
        ),
        MessageConversation(
          id: 'bert_pullman',
          name: 'Bert Pullman',
          status: 'Online',
          preview:
              'Congratulations on completing the first lesson, keep up the good work!',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 12)),
          accentColor: const Color(0xFFD8FAF0),
          isOnline: true,
        ),
        MessageConversation(
          id: 'daniel_lawson',
          name: 'Daniel Lawson',
          status: 'Online',
          preview:
              'Your course has been updated, you can check the new course in your study course.',
          timestamp: now.subtract(const Duration(hours: 2, minutes: 8)),
          accentColor: const Color(0xFFFFE4EB),
          isOnline: true,
          showMediaPreview: true,
        ),
        MessageConversation(
          id: 'nguyen_shane',
          name: 'Nguyen Shane',
          status: 'Offline',
          preview: 'Congratulations, you have completed your study target today.',
          timestamp: now.subtract(const Duration(hours: 12, minutes: 9)),
          accentColor: const Color(0xFFDDF8EF),
          isOnline: false,
        ),
      ],
      aiGuestMessages: <SupportChatMessage>[
        SupportChatMessage(
          id: 'message_1',
          text: _aiGuestWelcome,
          senderType: MessageSenderType.assistant,
          timestamp: now.subtract(const Duration(minutes: 3)),
        ),
      ],
      notifications: <AppNotificationItem>[
        AppNotificationItem(
          id: 'notification_1',
          title: 'Successful purchase!',
          message: 'Your Product Design v1.0 course is ready to start.',
          type: NotificationType.purchase,
          timestamp: now.subtract(const Duration(minutes: 2)),
          isRead: false,
        ),
        AppNotificationItem(
          id: 'notification_2',
          title: 'Congratulations on completing the first lesson',
          message: 'Keep the momentum going and start the next lesson.',
          type: NotificationType.message,
          timestamp: now.subtract(const Duration(minutes: 5)),
          isRead: false,
        ),
        AppNotificationItem(
          id: 'notification_3',
          title: 'Your course has been updated',
          message: 'Fresh material is available in your study plan.',
          type: NotificationType.update,
          timestamp: now.subtract(const Duration(minutes: 9)),
          isRead: false,
        ),
        AppNotificationItem(
          id: 'notification_4',
          title: 'Congratulations, you have unlocked a streak',
          message: 'You are showing up consistently this week.',
          type: NotificationType.celebration,
          timestamp: now.subtract(const Duration(minutes: 14)),
          isRead: false,
        ),
      ],
      nextNotificationId: 5,
      nextMessageId: 2,
    );
    await saveState(seededState);
    return seededState;
  }

  @override
  Future<void> saveState(MessageCenterState state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_stateKey, state.toJson());
  }

  @override
  Future<void> clearCachedState() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_stateKey);
  }

  @override
  Future<void> markNotificationsRead({List<String>? ids}) async {
    final currentState = await loadState();
    final targetIds = ids?.toSet();

    final updatedState = currentState.copyWith(
      notifications: currentState.notifications.map((notification) {
        if (targetIds == null || targetIds.contains(notification.id)) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList(),
    );

    await saveState(updatedState);
  }

  @override
  Future<List<SupportChatMessage>> loadConversationMessages(
    String conversationId,
  ) async {
    final currentState = await loadState();
    if (conversationId == 'ai_guest') {
      return currentState.aiGuestMessages;
    }

    final conversation = currentState.conversations.firstWhere(
      (item) => item.id == conversationId,
      orElse: () => MessageConversation(
        id: conversationId,
        name: 'Conversation',
        status: 'Offline',
        preview: '',
        timestamp: DateTime.now(),
        accentColor: const Color(0xFFE5EAFF),
        isOnline: false,
      ),
    );

    return <SupportChatMessage>[
      SupportChatMessage(
        id: 'seed_$conversationId',
        text: conversation.preview.isEmpty
            ? 'Start the conversation here.'
            : conversation.preview,
        senderType: MessageSenderType.assistant,
        timestamp: conversation.timestamp,
      ),
    ];
  }

  @override
  Future<SupportChatMessage> sendConversationMessage({
    required String conversationId,
    required String text,
  }) async {
    return SupportChatMessage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      senderType: MessageSenderType.user,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<String> getAiGuestReply(String prompt) async {
    final lowerPrompt = prompt.toLowerCase().trim();
    final smartReply = _smartReplyForPrompt(lowerPrompt);
    if (smartReply != null) {
      return smartReply;
    }

    final fallbacks = <String>[
      'I can help with courses, notifications, payments, profile settings, and lessons. Ask a more specific question and I will give a clearer answer.',
      'If your question is about a screen, course, payment, account feature, or support flow, I can guide you.',
      'You can ask me about course unlocks, playback, account updates, notifications, or support requests.',
    ];
    return fallbacks[_random.nextInt(fallbacks.length)];
  }

  bool _containsAny(String value, List<String> keywords) {
    return keywords.any(value.contains);
  }

  bool _containsAll(String value, List<String> keywords) {
    return keywords.every(value.contains);
  }

  String? _smartReplyForPrompt(String prompt) {
    if (_containsAny(prompt, <String>['hello', 'hi', 'hey', 'salam', 'assalam'])) {
      return 'Hello, I am AI Guest. Ask me anything about payments, lessons, account settings, support, or course access.';
    }

    if (_containsAny(prompt, <String>[
      'what can you do',
      'help me',
      'what do you know',
      'who are you',
    ])) {
      return 'I can help with onboarding, login, OTP, Product Design purchases, lesson access, progress, profile updates, notifications, messages, settings, and support requests inside the app.';
    }

    if (_containsAll(prompt, <String>['locked', 'lesson']) ||
        _containsAny(prompt, <String>['unlock lesson', 'lesson locked', 'locked video'])) {
      return 'Locked lessons are usually unlocked after purchasing the course. Free preview lessons can open immediately, and the remaining lessons become available once checkout and payment verification are completed.';
    }

    final topicScores = <String, int>{
      'purchase': _scoreMatches(prompt, <String>[
        'buy',
        'payment',
        'purchase',
        'checkout',
        'pay',
        'card',
        'cvv',
        'pin',
        'billing',
      ]),
      'auth': _scoreMatches(prompt, <String>[
        'login',
        'log in',
        'sign in',
        'signup',
        'sign up',
        'register',
        'otp',
        'verification',
        'verify',
      ]),
      'profile': _scoreMatches(prompt, <String>[
        'profile',
        'photo',
        'avatar',
        'account',
        'name',
        'email',
      ]),
      'password': _scoreMatches(prompt, <String>[
        'password',
        'change password',
        'forgot password',
        'reset password',
      ]),
      'course': _scoreMatches(prompt, <String>[
        'course',
        'product design',
        'lesson',
        'video',
        'player',
        'study',
      ]),
      'progress': _scoreMatches(prompt, <String>[
        'progress',
        'continue',
        'resume',
        'where i left',
      ]),
      'my_courses': _scoreMatches(prompt, <String>[
        'my courses',
        'purchased courses',
        'purchased course',
        'enrolled',
      ]),
      'favorites': _scoreMatches(prompt, <String>[
        'favorite',
        'favourite',
        'saved',
        'bookmark',
      ]),
      'notifications': _scoreMatches(prompt, <String>[
        'notification',
        'notifications',
        'alert',
        'reminder',
      ]),
      'messages': _scoreMatches(prompt, <String>[
        'message',
        'messages',
        'chat',
        'conversation',
      ]),
      'support': _scoreMatches(prompt, <String>[
        'support',
        'help',
        'ticket',
        'contact',
      ]),
      'settings': _scoreMatches(prompt, <String>[
        'setting',
        'settings',
        'privacy',
      ]),
      'dashboard': _scoreMatches(prompt, <String>[
        'dashboard',
        'home',
      ]),
    };

    final bestTopic = _bestTopic(topicScores);
    switch (bestTopic) {
      case 'purchase':
        return 'To buy the Product Design course, open the course screen, tap Buy Now, choose a payment method, enter your payment details, and then complete the payment password step.';
      case 'auth':
        return 'Use the sign up or login flow from the auth screens, then complete OTP verification if requested. If verification fails, check the phone number or email flow being used by your backend.';
      case 'profile':
        return 'You can update your name, email, phone number, bio, and profile photo from the Edit Account screen, and the saved profile data is reflected across the app.';
      case 'password':
        return 'Password updates are handled from Settings and Privacy. You can use Change Password for a normal update or Forgot Password if you need to reset access.';
      case 'course':
        return 'The Product Design course screen lets you review lessons, unlock the full course, and open the player. Free previews are available first, while the rest depend on purchase status.';
      case 'progress':
        return 'Your lesson progress is tracked inside the course flow, so after returning to the app you can continue from where you left off in the player experience.';
      case 'my_courses':
        return 'Purchased or unlocked content can be reviewed from My Courses, where the app checks your available course access and lets you jump back into learning.';
      case 'favorites':
        return 'Favorites help you return to saved content quickly. Open the favorites area or the relevant course section to review the items you marked.';
      case 'notifications':
        return 'The notifications screen shows course, message, security, and purchase updates. Unread notifications can be marked as read after they are opened.';
      case 'messages':
        return 'The Messages area lists your conversations, including AI Guest. You can open the chat screen, ask about app features, and continue the conversation from there.';
      case 'support':
        return 'If you need direct help, use the support request flow from the Help section. You can submit a subject and message, and the support team can follow up from there.';
      case 'settings':
        return 'Settings and Privacy lets you manage notification preferences, privacy options, and password changes from one place.';
      case 'dashboard':
        return 'The dashboard is the app home area where users can quickly continue learning, review their activity, and jump into the main course flow.';
      default:
        return null;
    }
  }

  int _scoreMatches(String value, List<String> keywords) {
    var score = 0;
    for (final keyword in keywords) {
      if (value.contains(keyword)) {
        score += keyword.contains(' ') ? 3 : 1;
      }
    }
    return score;
  }

  String? _bestTopic(Map<String, int> scores) {
    String? bestTopic;
    var bestScore = 0;

    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        bestTopic = entry.key;
        bestScore = entry.value;
      }
    }

    return bestScore == 0 ? null : bestTopic;
  }

  MessageCenterState _normalizeState(MessageCenterState state) {
    final normalizedConversations = state.conversations.map((conversation) {
      if (conversation.isAiGuest || conversation.id == 'ai_guest') {
        return conversation.copyWith(preview: _aiGuestPreview);
      }
      return conversation;
    }).toList();

    final normalizedAiGuestMessages = state.aiGuestMessages.isEmpty
        ? <SupportChatMessage>[
            SupportChatMessage(
              id: 'message_1',
              text: _aiGuestWelcome,
              senderType: MessageSenderType.assistant,
              timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
            ),
          ]
        : state.aiGuestMessages.asMap().entries.map((entry) {
            final message = entry.value;
            if (entry.key == 0 &&
                message.senderType == MessageSenderType.assistant) {
              return SupportChatMessage(
                id: message.id,
                text: _aiGuestWelcome,
                senderType: message.senderType,
                timestamp: message.timestamp,
              );
            }
            return message;
          }).toList();

    return state.copyWith(
      conversations: normalizedConversations,
      aiGuestMessages: normalizedAiGuestMessages,
    );
  }
}
