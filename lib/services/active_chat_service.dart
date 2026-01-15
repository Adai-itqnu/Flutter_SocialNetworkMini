/// Service to track which chat room is currently active/being viewed
/// Used to suppress notifications for messages in currently viewed chat
class ActiveChatService {
  static String? _activeChatId;

  /// Set the currently active chat room
  static void setActiveChat(String? chatId) {
    _activeChatId = chatId;
  }

  /// Get the currently active chat room ID
  static String? get activeChatId => _activeChatId;

  /// Check if a specific chat is currently active
  static bool isChatActive(String chatId) {
    return _activeChatId == chatId;
  }

  /// Clear the active chat (when leaving chat screen)
  static void clearActiveChat() {
    _activeChatId = null;
  }
}
