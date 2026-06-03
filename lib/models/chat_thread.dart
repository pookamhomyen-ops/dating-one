class ChatThread {
  const ChatThread({
    required this.id,
    required this.partnerName,
    required this.partnerPhotoUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  final String id;
  final String partnerName;
  final String partnerPhotoUrl;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isOnline;
}
