import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
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
    Get.to(() => ConversationChatScreen(conversation: conversation));
  }

  Future<void> _refreshInbox() async {
    await _messageCenterController.refreshState();
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
                  child: RefreshIndicator(
                    onRefresh: _refreshInbox,
                    color: AppColors.primary,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _selectedTab == _InboxTab.message
                          ? ListView.builder(
                              key: const ValueKey('message-list'),
                              physics: const AlwaysScrollableScrollPhysics(),
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
                              physics: const AlwaysScrollableScrollPhysics(),
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
                                    onTap: () => controller.markNotificationRead(
                                      notification.id,
                                    ),
                                  ),
                                );
                              },
                            ),
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
  static const List<String> _aiGuestPromptSuggestions = <String>[
    'How do I buy the Product Design course?',
    'Why is my lesson still locked?',
    'How do I update my profile photo?',
    'How can I change my password?',
    'Where can I see my purchased courses?',
    'How do notifications work in this app?',
    'How do I contact support?',
    'How can I continue a lesson where I left off?',
  ];

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  String _draftText = '';

  MessageCenterController get _messageCenterController =>
      Get.find<MessageCenterController>();

  @override
  void initState() {
    super.initState();
    _messageFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
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

  void _handleFocusChange() {
    if (_messageFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    setState(() {});
  }

  void _updateDraft(String value) {
    setState(() {
      _draftText = value;
    });
  }

  void _applySuggestion(String suggestion) {
    _messageController.value = TextEditingValue(
      text: suggestion,
      selection: TextSelection.collapsed(offset: suggestion.length),
    );
    _messageFocusNode.requestFocus();
    _updateDraft(suggestion);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  List<String> get _filteredSuggestions {
    final query = _draftText.trim().toLowerCase();
    if (query.isEmpty) {
      return _aiGuestPromptSuggestions.take(4).toList();
    }

    final filtered = _aiGuestPromptSuggestions.where((suggestion) {
      return suggestion.toLowerCase().contains(query);
    }).toList();

    return (filtered.isEmpty ? _aiGuestPromptSuggestions : filtered)
        .take(5)
        .toList();
  }

  bool get _showSuggestions =>
      _messageFocusNode.hasFocus || _draftText.trim().isNotEmpty;

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    _messageController.clear();
    _updateDraft('');
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
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: GetBuilder<MessageCenterController>(
        builder: (controller) {
          final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
          final canSend =
              _messageController.text.trim().isNotEmpty &&
              !controller.isAiGuestTyping;

          return AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: viewInsetsBottom),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showSuggestions && _filteredSuggestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      child: _AiSuggestionPanel(
                        suggestions: _filteredSuggestions,
                        onSelect: _applySuggestion,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _messageFocusNode,
                            textInputAction: TextInputAction.send,
                            minLines: 1,
                            maxLines: 4,
                            onTap: _scrollToBottom,
                            onChanged: _updateDraft,
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
                        _AiSendButton(
                          enabled: canSend,
                          onTap: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

class ConversationChatScreen extends StatefulWidget {
  const ConversationChatScreen({
    super.key,
    required this.conversation,
  });

  final MessageConversation conversation;

  @override
  State<ConversationChatScreen> createState() => _ConversationChatScreenState();
}

class _ConversationChatScreenState extends State<ConversationChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  MessageCenterController get _messageCenterController =>
      Get.find<MessageCenterController>();

  @override
  void initState() {
    super.initState();
    _messageCenterController.loadConversationMessages(widget.conversation.id);
    _messageFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_messageFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    setState(() {});
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
    await _messageCenterController.sendConversationMessage(
      widget.conversation,
      text,
    );
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
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: GetBuilder<MessageCenterController>(
        builder: (controller) {
          final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
          final canSend =
              _messageController.text.trim().isNotEmpty &&
              !controller.isConversationSending(widget.conversation.id);

          return AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: viewInsetsBottom),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 4,
                        onTap: _scrollToBottom,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
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
                    _AiSendButton(
                      enabled: canSend,
                      onTap: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      body: SafeArea(
        child: GetBuilder<MessageCenterController>(
          builder: (controller) {
            final messages = controller.messagesForConversation(
              widget.conversation.id,
            );
            final isLoading = controller.isConversationLoading(
              widget.conversation.id,
            );

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
                      _ConversationAvatar(
                        accentColor: widget.conversation.accentColor,
                        icon: Icons.person_rounded,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.conversation.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.heading,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              controller.isConversationSending(
                                widget.conversation.id,
                              )
                                  ? 'Sending...'
                                  : widget.conversation.status,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: widget.conversation.isOnline
                                    ? AppColors.primary
                                    : AppColors.mutedText,
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
                  child: isLoading && messages.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ChatBubble(message: messages[index]),
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
    required this.onTap,
  });

  final AppNotificationItem notification;
  final String timeLabel;
  final VoidCallback onTap;

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
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: notification.isRead
                              ? const Color(0xFFD5D7E9)
                              : AppColors.warmAccent,
                        ),
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
        ),
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

class _AiSuggestionPanel extends StatelessWidget {
  const _AiSuggestionPanel({
    required this.suggestions,
    required this.onSelect,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smart suggestions',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return _AiSuggestionChip(
                label: suggestion,
                onTap: () => onSelect(suggestion),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AiSuggestionChip extends StatelessWidget {
  const _AiSuggestionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.inputBorder,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.heading,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AiSendButton extends StatelessWidget {
  const _AiSendButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.primary : AppColors.inputBorder,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            Icons.arrow_upward_rounded,
            color: enabled ? Colors.white : AppColors.mutedText,
          ),
        ),
      ),
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
