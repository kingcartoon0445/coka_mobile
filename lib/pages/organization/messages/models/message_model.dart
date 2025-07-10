import 'dart:convert';

class Message {
  final String id;
  final String? conversationId;
  final String? messageId;
  final String? from;
  final String fromName;
  final String? to;
  final String? toName;
  final String message;
  final bool isFromMe;
  final int? timestamp;
  final bool? isGpt;
  final String? type;
  final String fullName;
  final int? status;
  final List<Attachment>? attachments;
  final String? localId;
  final bool sending;
  final FileAttachment? fileAttachment;

  Message({
    required this.id,
    required this.conversationId,
    this.messageId,
    this.from,
    required this.fromName,
    this.to,
    this.isFromMe = false,
    this.toName,
    required this.message,
    this.timestamp,
    this.isGpt,
    this.type,
    required this.fullName,
    this.status,
    this.attachments,
    this.localId,
    this.sending = false,
    this.fileAttachment,
  });

  // bool get isFromMe =>
  //     from != '124662217400086'; // Tin nhắn từ khách hàng khi from khác ID của page

  String get content => message;

  String get senderName => fromName;

  String? get senderAvatar => null; // TODO: Add avatar from API if available

  factory Message.fromJson(Map<String, dynamic> json) {
    List<Attachment>? attachments;
    if (json['attachments'] != null) {
      try {
        final List<dynamic> attachmentsList =
            json['attachments'] is String ? jsonDecode(json['attachments']) : json['attachments'];
        attachments = attachmentsList.map((e) => Attachment.fromJson(e)).toList();
      } catch (e) {
        print('Error parsing attachments: $e');
      }
    }

    FileAttachment? fileAttachment;
    if (json['fileAttachment'] != null) {
      try {
        fileAttachment = FileAttachment.fromJson(json['fileAttachment']);
      } catch (e) {
        print('Error parsing fileAttachment: $e');
      }
    }

    return Message(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      messageId: json['messageId'] ?? '',
      from: json['from'] ?? '',
      isFromMe: json['isPageReply'] ?? false, // ID của page
      fromName: json['fromName'] ?? '',
      to: json['to'] ?? '',
      toName: json['toName'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] is int
          ? json['timestamp']
          : int.tryParse(json['timestamp']?.toString() ?? '0') ?? 0,
      isGpt: json['isGpt'] ?? false,
      type: json['type'] ?? 'MESSAGE',
      fullName: json['fullName'] ?? '',
      status: json['status'] ?? 0,
      attachments: attachments,
      localId: json['localId'],
      sending: json['sending'] ?? false,
      fileAttachment: fileAttachment,
    );
  }
}

class Attachment {
  final String type;
  final String url;
  final String? name;
  final Map<String, dynamic>? payload;

  Attachment({
    required this.type,
    required this.url,
    this.name,
    this.payload,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>?;
    final url = payload?['url']?.toString() ?? json['url']?.toString() ?? '';

    return Attachment(
      type: json['type']?.toString() ?? '',
      url: url,
      name: json['name']?.toString(),
      payload: payload,
    );
  }
}

class FileAttachment {
  final String name;
  final String type;
  final int size;
  final String url;

  FileAttachment({
    required this.name,
    required this.type,
    required this.size,
    required this.url,
  });

  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    return FileAttachment(
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      size: json['size'] is int ? json['size'] : int.tryParse(json['size']?.toString() ?? '0') ?? 0,
      url: json['url']?.toString() ?? '',
    );
  }
}
