import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:coka/constants.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../api/repositories/message_repository.dart';
import '../models/message_model.dart';
import './message_state.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return ChatNotifier(repository);
});

class ChatState {
  final bool isLoading;
  final List<Message> messages;
  final int page;
  final bool hasMore;
  final bool isSending;
  final Map<String, String> messageErrors;
  final String? errorMessage;
  ChatState({
    this.isLoading = false,
    this.messages = const [],
    this.page = 0,
    this.hasMore = true,
    this.isSending = false,
    this.messageErrors = const {},
    this.errorMessage,
  });

  ChatState copyWith({
    bool? isLoading,
    List<Message>? messages,
    int? page,
    bool? hasMore,
    String? errorMessage,
    bool? isSending,
    Map<String, String>? messageErrors,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      page: page ?? this.page,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      isSending: isSending ?? this.isSending,
      messageErrors: messageErrors ?? this.messageErrors,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final MessageRepository _repository;
  StreamSubscription? _onChangedListener;
  ChatNotifier(this._repository) : super(ChatState());
  @override
  void dispose() {
    _onChangedListener?.cancel();
    super.dispose();
  }

  Future<void> loadMessages(String organizationId, String conversationId,
      {bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = ChatState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      final response = await _repository.getChatList(
        organizationId,
        conversationId,
        refresh ? 0 : state.page,
      );

      final List<Message> messages =
          (response['content'] as List).map((item) => Message.fromJson(item)).toList();

      if (refresh) {
        state = state.copyWith(
          messages: messages,
          isLoading: false,
          hasMore: messages.length >= 20,
          page: 1,
        );
      } else {
        state = state.copyWith(
          messages: [...state.messages, ...messages],
          isLoading: false,
          hasMore: messages.length >= 20,
          page: state.page + 1,
        );
      }
    } catch (e) {
      print('Error loading messages: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  // Add local message ngay lập tức (optimistic UI như web)
  void addLocalMessage(Message localMessage) {
    state = state.copyWith(
      messages: [localMessage, ...state.messages],
    );
  }

  Future getOData() async {
    final organList = await fetchOrganList();
    // final prefs = await SharedPreferences.getInstance();
    if (organList == null || organList.isEmpty) {
      return Future.error('No organizations found');
    }

    return organList[0];
  }

  void setupFirebaseListener(String organizationId, String conversationId) async {
    final oData = await getOData();
    final oId = oData["id"];

    // Cancel listener cũ nếu có
    await _onChangedListener?.cancel();

    final ref = FirebaseDatabase.instance.ref(
      'root/OrganizationId: $oId/CreateOrUpdateConversation',
    );

    _onChangedListener = ref.onValue.listen((event) {
      final snapshot = event.snapshot;
      final data = (snapshot.value ?? {}) as Map;
      log("Data changed: ${data.toString()}");

      final dataMess = data["ConversationId: $conversationId"];
      if (dataMess is Map && dataMess["ConversationId"] == conversationId) {
        Attachment? fileAttachment;
        // Nếu có file đính kèm, parse nó
        if (dataMess.containsKey("Attachments")) {
          final outerKeys = dataMess["Attachments"];
          final List<dynamic> decodedList = jsonDecode(outerKeys);

          for (final outerKey in decodedList) {
            fileAttachment = Attachment.fromJson(outerKey as Map<String, dynamic>);
          }
        }

        // final attachments =
        //     decodedList.map((e) => MessageAttachment.fromJson(e as Map<String, dynamic>)).toList();

        final message = Message(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          message: dataMess.containsKey("Message") ? dataMess["Message"] : "",
          to: dataMess["To"],
          toName: dataMess["ToName"],
          from: dataMess["From"],
          isFromMe: dataMess["IsPageReply"] ?? true,
          fromName: dataMess["FromName"],
          timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          isGpt: false,
          type: dataMess["Type"] ?? "MESSAGE",
          fullName: dataMess["FullName"],
          status: 0,
          sending: false,
          // fileAttachment: fileAttachment,
          attachments:
              fileAttachment != null ? [fileAttachment] : [], // Chỉ thêm nếu có fileAttachment
          conversationId: conversationId,
        );

        addMessage(message);
      }
    });
  }

  Future<void> sendMessage(
    String organizationId,
    String conversationId,
    String content, {
    List<Map<String, dynamic>>? attachments,
  }) async {
    if (content.trim().isEmpty) return;

    state = state.copyWith(isSending: true);

    // Tạo tin nhắn local với localId (theo logic web)
    String localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    if (state.messages.last.type == "FEED") {
      localId = state.messages.first.messageId ?? "";
      log("localId: $localId");
    }
    final localMessage = Message(
      id: '', // Không có id server
      localId: localId, // LocalId để identify
      conversationId: conversationId,
      messageId: localId,
      from: '124662217400086', // Page ID
      fromName: 'You',
      to: '',
      isFromMe: true, // Tin nhắn từ page
      toName: '',
      message: content,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      isGpt: false,
      type: 'MESSAGE',
      fullName: 'You', // TODO: Get from user profile
      status: 0,
      sending: true, // Đang gửi
      attachments: attachments?.map((e) => Attachment.fromJson(e)).toList(),
    );

    // Thêm tin nhắn local ngay lập tức
    addLocalMessage(localMessage);

    try {
      final response = await _repository.sendFacebookMessage(
        organizationId,
        conversationId,
        content,
        messageId: localId,
        attachments: attachments,
      );
      if (response['status'] != 0) {
        state = state.copyWith(errorMessage: response['message']);
      }
      // Server sẽ trả về tin nhắn thật qua Firebase/WebSocket
      // Ta chỉ cần remove local message khi server message arrive
      _removeLocalMessage(localId);
    } catch (e) {
      print('Error sending message: $e');

      // Mark local message as failed
      _markMessageAsFailed(localId, e.toString());
      // Rethrow để UI có thể hiển thị toast
      rethrow;
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  Future<void> sendImageMessage(
    String organizationId,
    String conversationId,
    XFile imageFile, {
    String? textContent,
  }) async {
    state = state.copyWith(isSending: true);

    // Tạo local message với ảnh (theo logic web: ảnh vào attachments)
    String localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    if (state.messages.first.type == "FEED") {
      localId = state.messages.first.messageId ?? "";
    }
    final localMessage = Message(
      id: '', // Không có id server
      localId: localId,
      conversationId: conversationId,
      messageId: localId,
      from: '124662217400086',
      fromName: 'You',
      isFromMe: true, // Tin nhắn từ page
      to: '',
      toName: '',
      message: textContent ?? '', // Text message nếu có
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      isGpt: false,
      type: 'MESSAGE',
      fullName: 'You',
      status: 0,
      sending: true,
      // ẢNH: Lưu vào attachments (như web)
      attachments: [
        Attachment(
          type: 'image',
          url: 'file://${imageFile.path}', // Local file URL
          name: imageFile.name,
          payload: {
            'url': 'file://${imageFile.path}',
            'name': imageFile.name,
          },
        ),
      ],
    );

    // Hiển thị ngay lập tức
    addLocalMessage(localMessage);

    try {
      final response = await _repository.sendImageMessage(
        organizationId,
        conversationId,
        imageFile,
        textMessage: textContent,
      );

      // Remove local message, server message sẽ arrive qua Firebase
      _removeLocalMessage(localId);
    } catch (e) {
      print('Error sending image: $e');
      _markMessageAsFailed(localId, e.toString());
      // Rethrow để UI có thể hiển thị toast
      rethrow;
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  Future<void> sendFileMessage(
    String organizationId,
    String conversationId,
    File file, {
    String? textContent,
  }) async {
    state = state.copyWith(isSending: true);

    final fileName = file.path.split('/').last;

    // Tạo local message với file (theo logic web: file khác vào fileAttachment)
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final localMessage = Message(
      id: '', // Không có id server
      localId: localId,
      conversationId: conversationId,
      messageId: localId,
      from: '124662217400086',
      fromName: 'You',
      to: '',
      toName: '',
      isFromMe: true, // Tin nhắn từ page
      message: textContent ?? '', // Text message nếu có
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      isGpt: false,
      type: 'MESSAGE',
      fullName: 'You',
      status: 0,
      sending: true,
      // FILE KHÁC: Lưu vào fileAttachment (như web)
      fileAttachment: FileAttachment(
        name: fileName,
        type: _getFileType(fileName),
        size: file.lengthSync(),
        url: 'file://${file.path}', // Local file URL
      ),
    );

    // Hiển thị ngay lập tức
    addLocalMessage(localMessage);

    try {
      final response = await _repository.sendFileMessage(
        organizationId,
        conversationId,
        file,
        textMessage: textContent,
      );

      // Remove local message, server message sẽ arrive qua Firebase
      _removeLocalMessage(localId);
    } catch (e) {
      print('Error sending file: $e');
      _markMessageAsFailed(localId, e.toString());
      // Rethrow để UI có thể hiển thị toast
      rethrow;
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  // Helper method để get file type
  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  // Remove local message khi server message arrive
  void _removeLocalMessage(String localId) {
    final updatedMessages = state.messages.where((msg) => msg.localId != localId).toList();
    state = state.copyWith(messages: updatedMessages);
  }

  // Mark local message as failed
  void _markMessageAsFailed(String localId, String error) {
    final updatedMessages = state.messages.map((msg) {
      if (msg.localId == localId) {
        return Message(
          id: msg.id,
          localId: msg.localId,
          conversationId: msg.conversationId,
          messageId: msg.messageId,
          from: msg.from,
          fromName: msg.fromName,
          to: msg.to,
          toName: msg.toName,
          message: msg.message,
          timestamp: msg.timestamp,
          isGpt: msg.isGpt,
          type: msg.type,
          fullName: msg.fullName,
          status: 2, // Error status
          sending: false,
          attachments: msg.attachments,
          fileAttachment: msg.fileAttachment,
        );
      }
      return msg;
    }).toList();

    final newErrors = Map<String, String>.from(state.messageErrors);
    newErrors[localId] = error;

    state = state.copyWith(
      messages: updatedMessages,
      messageErrors: newErrors,
    );
  }

  void addMessage(Message message) {
    state = state.copyWith(
      messages: [message, ...state.messages],
    );
  }

  void clearMessageError(String messageId) {
    if (state.messageErrors.containsKey(messageId)) {
      final newErrors = Map<String, String>.from(state.messageErrors);
      newErrors.remove(messageId);
      state = state.copyWith(messageErrors: newErrors);
    }
  }

  Future<void> resendMessage(
    String organizationId,
    String conversationId,
    String messageId,
    String content, {
    List<Map<String, dynamic>>? attachments,
  }) async {
    clearMessageError(messageId);

    await sendMessage(
      organizationId,
      conversationId,
      content,
      attachments: attachments,
    );
  }

  // Gửi ảnh lên server (không tạo local message)
  Future<void> sendImageToServer(
    String organizationId,
    String conversationId,
    XFile imageFile,
    String localId, {
    String? textMessage,
  }) async {
    try {
      final response = await _repository.sendImageMessage(
        organizationId,
        conversationId,
        imageFile,
        textMessage: textMessage,
      );

      // Remove local message sau khi server trả về thành công
      _removeLocalMessage(localId);
    } catch (e) {
      print('Error sending image: $e');
      _markMessageAsFailed(localId, e.toString());
      // Rethrow để UI có thể hiển thị toast
      rethrow;
    }
  }

  // Gửi file lên server (không tạo local message)
  Future<void> sendFileToServer(
    String organizationId,
    String conversationId,
    File file,
    String localId, {
    String? textMessage,
  }) async {
    try {
      final response = await _repository.sendFileMessage(
        organizationId,
        conversationId,
        file,
        textMessage: textMessage,
      );

      // Remove local message sau khi server trả về thành công
      _removeLocalMessage(localId);
    } catch (e) {
      print('Error sending file: $e');
      _markMessageAsFailed(localId, e.toString());
      // Rethrow để UI có thể hiển thị toast
      rethrow;
    }
  }
}
