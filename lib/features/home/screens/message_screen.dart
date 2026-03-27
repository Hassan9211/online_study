import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../controllers/message_center_controller.dart';

enum _InboxTab { message, notification }

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  _InboxTab _selectedTab = _InboxTab.message;

  MessageCenterController get _messageCenterController =>
      Get.find<MessageCenterController>();

  void _selectTab(_InboxTab tab) {
    setState(() {
      _selectedTab = tab;
    });

    if (tab == _InboxTab.notification) {
      _messageCenterController.markNotificationsSeen();
    }
  }

  void _openConversation(MessageConversation conversation) {
    if (conversation.isAiGuest) {
      Get.to(() => const AiGuestChatScreen());
      return;
    }

    Get.snackbar(
      conversation.name,
      'Is conversation ko hum next step me full chat me bhi open kar sakte hain.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: AppColors.heading,
      margin: const EdgeInsets.all(14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: GetBuilder<MessageCenterController>(
          builder: (controller) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                  child: Text(
                    'Notifications',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.heading,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'message',
                          isSelected: _selectedTab == _InboxTab.message,
                          onTap: () => _selectTab(_InboxTab.message),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: 'notification',
                          isSelected: _selectedTab == _InboxTab.notification,
                          showDot: controller.hasUnreadNotifications,
                          onTap: () => _selectTab(_InboxTab.notification),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _selectedTab == _InboxTab.message
                        ? ListView.builder(
                            key: const ValueKey('message-list'),
                            padding: const EdgeInsets.fromLTRB(10, 4, 10, 112),
                            itemCount: controller.conversations.length,
                            itemBuilder: (context, index) {
                              final conversation =
                                  controller.conversations[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _ConversationCard(
                                  conversation: conversation,
                                  timeLabel: controller.conversationTimeLabel(
                                    conversation.timestamp,
                                  ),
                                  onTap: () => _openConversation(conversation),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            key: const ValueKey('notification-list'),
                            padding: const EdgeInsets.fromLTRB(10, 4, 10, 112),
                            itemCount: controller.notifications.length,
                            itemBuilder: (context, index) {
                              final notification =
                                  controller.notifications[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _NotificationCard(
                                  notification: notification,
                                  timeLabel: controller.notificationTimeLabel(
                                    notification.timestamp,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AiGuestChatScreen extends StatefulWidget {
  const AiGuestChatScreen({super.key});

  @override
  State<AiGuestChatScreen> createState() => _AiGuestChatScreenState();
}

class _AiGuestChatScreenState extends State<AiGuestChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  MessageCenterController get _messageCenterController =>
      Get.find<MessageCenterController>();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    _messageController.clear();
    await _messageCenterController.sendAiGuestMessage(text);
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Ask AI Guest anything...',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 64,
                child: AppPrimaryButton(label: 'Send', onPressed: _sendMessage),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: GetBuilder<MessageCenterController>(
          builder: (controller) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToBottom(),
            );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: Get.back,
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.heading,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const _ConversationAvatar(
                        accentColor: Color(0xFFE5EAFF),
                        icon: Icons.smart_toy_rounded,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Guest',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.heading,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              controller.isAiGuestTyping
                                  ? 'Typing...'
                                  : 'Online now',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    itemCount:
                        controller.aiGuestMessages.length +
                        (controller.isAiGuestTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.aiGuestMessages.length &&
                          controller.isAiGuestTyping) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: _TypingBubble(),
                        );
                      }

                      final message = controller.aiGuestMessages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChatBubble(message: message),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showDot = false,
  });

  final String label;
  final bool isSelected;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (showDot) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.warmAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2.5,
              width: 54,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.timeLabel,
    required this.onTap,
  });

  final MessageConversation conversation;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.heading.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ConversationAvatar(
                    accentColor: conversation.accentColor,
                    icon: conversation.isAiGuest
                        ? Icons.smart_toy_rounded
                        : Icons.person_rounded,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.heading,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          conversation.status,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: conversation.isOnline
                                ? const Color(0xFF61B98C)
                                : AppColors.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    timeLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                conversation.preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedText,
                  height: 1.45,
                ),
              ),
              if (conversation.showMediaPreview) ...[
                const SizedBox(height: 16),
                Container(
                  height: 126,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4EB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.timeLabel,
  });

  final AppNotificationItem notification;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final iconData = switch (notification.type) {
      NotificationType.purchase => Icons.receipt_long_rounded,
      NotificationType.message => Icons.chat_bubble_rounded,
      NotificationType.update => Icons.menu_book_rounded,
      NotificationType.celebration => Icons.emoji_events_rounded,
      NotificationType.reminder => Icons.notifications_active_rounded,
      NotificationType.security => Icons.lock_rounded,
    };

    final iconColor = switch (notification.type) {
      NotificationType.purchase => const Color(0xFFFF7A38),
      NotificationType.message => AppColors.primary,
      NotificationType.update => AppColors.primary,
      NotificationType.celebration => const Color(0xFFFFB13D),
      NotificationType.reminder => const Color(0xFF53B989),
      NotificationType.security => const Color(0xFFE15A5A),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.heading.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  notification.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Color(0xFFD5D7E9)),
                    const SizedBox(width: 6),
                    Text(
                      timeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({required this.accentColor, required this.icon});

  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final SupportChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bubbleColor = message.isUser
        ? AppColors.primary
        : const Color(0xFFF5F6FC);
    final textColor = message.isUser ? Colors.white : AppColors.heading;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            message.text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: textColor, height: 1.45),
          ),
        ),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TypingDot(),
            SizedBox(width: 4),
            _TypingDot(),
            SizedBox(width: 4),
            _TypingDot(),
          ],
        ),
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  const _TypingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.mutedText,
        shape: BoxShape.circle,
      ),
    );
  }
}
