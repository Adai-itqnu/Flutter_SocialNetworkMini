/// Service theo dõi chat room đang active
/// Dùng để bỏ qua notification cho tin nhắn trong chat đang xem
class ActiveChatService {
  static String? _activeChatId;

  // Đặt chat room đang active
  static void setActiveChat(String? chatId) => _activeChatId = chatId;

  // Lấy ID chat room đang active
  static String? get activeChatId => _activeChatId;

  // Kiểm tra 1 chat có đang active không
  static bool isChatActive(String chatId) => _activeChatId == chatId;

  // Xóa active chat (khi rời màn hình chat)
  static void clearActiveChat() => _activeChatId = null;
}
