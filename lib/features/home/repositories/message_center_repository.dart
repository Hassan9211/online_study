import '../models/message_center_models.dart';

abstract interface class MessageCenterRepository {
  Future<MessageCenterState> loadState();
  Future<void> saveState(MessageCenterState state);
  Future<String> getAiGuestReply(String prompt);
}
