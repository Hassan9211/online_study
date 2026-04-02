import '../models/message_center_models.dart';

abstract interface class MessageCenterRepository {
  Future<MessageCenterState> loadCachedState();
  Future<MessageCenterState> loadState();
  Future<void> saveState(MessageCenterState state);
  Future<void> clearCachedState();
  Future<String> getAiGuestReply(String prompt);
  Future<void> markNotificationsRead({List<String>? ids});
  Future<List<SupportChatMessage>> loadConversationMessages(String conversationId);
  Future<SupportChatMessage> sendConversationMessage({
    required String conversationId,
    required String text,
  });
}
