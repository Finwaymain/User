class SupportQuickQuestionModel {
  final int id;
  final String userType;
  final String category;
  final String question;
  final String? autoReply;
  final int sortOrder;
  final String status;

  SupportQuickQuestionModel({
    required this.id,
    required this.userType,
    required this.category,
    required this.question,
    this.autoReply,
    required this.sortOrder,
    required this.status,
  });

  factory SupportQuickQuestionModel.fromJson(Map<String, dynamic> json) {
    return SupportQuickQuestionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userType: json['user_type']?.toString() ?? 'customer',
      category: json['category']?.toString() ?? 'General',
      question: json['question']?.toString() ?? '',
      autoReply: json['auto_reply']?.toString(),
      sortOrder: json['sort_order'] is int ? json['sort_order'] : int.tryParse(json['sort_order'].toString()) ?? 0,
      status: json['status']?.toString() ?? 'active',
    );
  }
}

class SupportTicketModel {
  final int id;
  final String ticketNumber;
  final int userId;
  final String userType;
  final String userName;
  final String userPhone;
  final String? userEmail;
  final String? userPhoto;
  final String? topic;
  final String? lastMessage;
  final String? lastMessageAt;
  final String lastSender;
  final int unreadAdminCount;
  final int unreadUserCount;
  final String status;

  SupportTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.userId,
    required this.userType,
    required this.userName,
    required this.userPhone,
    this.userEmail,
    this.userPhoto,
    this.topic,
    this.lastMessage,
    this.lastMessageAt,
    required this.lastSender,
    required this.unreadAdminCount,
    required this.unreadUserCount,
    required this.status,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      ticketNumber: json['ticket_number']?.toString() ?? '',
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      userType: json['user_type']?.toString() ?? 'customer',
      userName: json['user_name']?.toString() ?? '',
      userPhone: json['user_phone']?.toString() ?? '',
      userEmail: json['user_email']?.toString(),
      userPhoto: json['user_photo']?.toString(),
      topic: json['topic']?.toString(),
      lastMessage: json['last_message']?.toString(),
      lastMessageAt: json['last_message_at']?.toString(),
      lastSender: json['last_sender']?.toString() ?? 'user',
      unreadAdminCount: json['unread_admin_count'] is int ? json['unread_admin_count'] : int.tryParse(json['unread_admin_count'].toString()) ?? 0,
      unreadUserCount: json['unread_user_count'] is int ? json['unread_user_count'] : int.tryParse(json['unread_user_count'].toString()) ?? 0,
      status: json['status']?.toString() ?? 'active',
    );
  }
}

class SupportMessageModel {
  final int id;
  final int ticketId;
  final int senderId;
  final String senderType; // 'customer', 'business', 'admin'
  final String senderName;
  final String message;
  final String? attachment;
  final bool isRead;
  final String? createdAt;

  SupportMessageModel({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderType,
    required this.senderName,
    required this.message,
    this.attachment,
    required this.isRead,
    this.createdAt,
  });

  bool get isAdmin => senderType == 'admin';

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) {
    return SupportMessageModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      ticketId: json['ticket_id'] is int ? json['ticket_id'] : int.tryParse(json['ticket_id'].toString()) ?? 0,
      senderId: json['sender_id'] is int ? json['sender_id'] : int.tryParse(json['sender_id'].toString()) ?? 0,
      senderType: json['sender_type']?.toString() ?? 'customer',
      senderName: json['sender_name']?.toString() ?? 'Support',
      message: json['message']?.toString() ?? '',
      attachment: json['attachment']?.toString(),
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      createdAt: json['created_at']?.toString(),
    );
  }
}
