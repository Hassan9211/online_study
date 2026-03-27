import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message_center_models.dart';
import 'message_center_repository.dart';

class LocalMessageCenterRepository implements MessageCenterRepository {
  static const String _stateKey = 'message_center_state';

  final Random _random = Random();

  @override
  Future<MessageCenterState> loadState() async {
    final preferences = await SharedPreferences.getInstance();
    final savedState = preferences.getString(_stateKey);

    if (savedState != null && savedState.isNotEmpty) {
      return MessageCenterState.fromJson(savedState);
    }

    final now = DateTime.now();
    final seededState = MessageCenterState(
      conversations: <MessageConversation>[
        MessageConversation(
          id: 'ai_guest',
          name: 'AI Guest',
          status: 'AI assistant',
          preview:
              'Ask me anything about courses, videos, payments, or your account.',
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
          text:
              'Assalamualaikum, main AI Guest hun. Aap course, payment, profile, password, ya videos ke bare me sawal kar sakte hain.',
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
  Future<String> getAiGuestReply(String prompt) async {
    final lowerPrompt = prompt.toLowerCase();

    if (_containsAny(lowerPrompt, <String>['hello', 'hi', 'salam', 'assalam'])) {
      return 'Wa alaikum assalam. Main AI Guest hun, batayein aap ko kis cheez me help chahiye?';
    }

    if (_containsAny(lowerPrompt, <String>['buy', 'payment', 'purchase', 'pay'])) {
      return 'Course khareedne ke liye Product Design screen par Buy Now tap karein, payment method choose karein aur password complete karein.';
    }

    if (_containsAny(lowerPrompt, <String>['video', 'lesson', 'play', 'player'])) {
      return 'Video player top par rahega aur neeche playable lessons. Agar koi lesson lock hai to pehle course unlock karna hoga.';
    }

    if (_containsAny(lowerPrompt, <String>['password', 'change password'])) {
      return 'Settings and Privacy ke andar Change Password screen se current password, new password, aur confirm password ke sath update kar sakte hain.';
    }

    if (_containsAny(lowerPrompt, <String>['profile', 'photo', 'name', 'account'])) {
      return 'Edit Account screen se name, email, aur profile photo update hogi aur woh poori app me sync ho jayegi.';
    }

    if (_containsAny(lowerPrompt, <String>['course', 'product design', 'study'])) {
      return 'Aap My Courses aur Course tab se apna course open kar sakte hain. Product Design v1.0 me videos ki real duration aur progress dono show ho rahi hain.';
    }

    final fallbacks = <String>[
      'Main courses, notifications, payments, profile, aur lessons ke bare me help kar sakta hun. Aap apna sawal thora aur specific likh dein.',
      'Agar aap kisi screen, course, payment, ya account feature ke bare me poochna chahte hain to main help kar sakta hun.',
      'Aap mujhe course unlock, playback, account update, ya support request ke bare me sawal bhej sakte hain.',
    ];
    return fallbacks[_random.nextInt(fallbacks.length)];
  }

  bool _containsAny(String value, List<String> keywords) {
    return keywords.any(value.contains);
  }
}
