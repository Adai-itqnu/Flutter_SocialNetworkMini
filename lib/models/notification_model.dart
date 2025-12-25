class NotificationModel {
  final int id;
  final String userName;
  final String content;
  final String time;
  final String type;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userName,
    required this.content,
    required this.time,
    required this.type,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userName: json['userName'],
      content: json['content'],
      time: json['time'],
      type: json['type'],
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'content': content,
      'time': time,
      'type': type,
      'isRead': isRead,
    };
  }
}