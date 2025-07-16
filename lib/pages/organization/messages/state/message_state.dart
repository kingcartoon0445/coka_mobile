import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:coka/constants.dart';
import 'package:coka/pages/organization/messages/models/message_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../api/api_client.dart';
import '../../../../api/repositories/message_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MessageRepository(apiClient);
});

// Provider riêng cho từng loại tin nhắn
final zaloMessageProvider = StateNotifierProvider<MessageNotifier, MessageState>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return MessageNotifier(repository, 'ZALO');
});

final facebookMessageProvider = StateNotifierProvider<MessageNotifier, MessageState>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return MessageNotifier(repository, 'FACEBOOK');
});

final allMessageProvider = StateNotifierProvider<MessageNotifier, MessageState>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return MessageNotifier(repository);
});

class MessageState {
  final bool isLoading;
  final List<Conversation> conversations;
  final Conversation? selectedConversation;
  final int page;
  final bool hasMore;
  final String? searchText;
  final String? provider;

  MessageState({
    this.isLoading = false,
    this.conversations = const [],
    this.selectedConversation,
    this.page = 0,
    this.hasMore = true,
    this.searchText,
    this.provider,
  });

  MessageState copyWith({
    bool? isLoading,
    List<Conversation>? conversations,
    Conversation? selectedConversation,
    int? page,
    bool? hasMore,
    String? searchText,
    String? provider,
  }) {
    return MessageState(
      isLoading: isLoading ?? this.isLoading,
      conversations: conversations ?? this.conversations,
      selectedConversation: selectedConversation ?? this.selectedConversation,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      searchText: searchText ?? this.searchText,
      provider: provider ?? this.provider,
    );
  }
}

class Conversation {
  final String id;
  final String pageId;
  final String pageName;
  final String? pageAvatar;
  final String personId;
  final String personName;
  final String? personAvatar;
  final String snippet;
  final bool canReply;
  final bool isFileMessage;
  final DateTime updatedTime;
  final int gptStatus;
  final bool isRead;
  final String type;
  final String provider;
  final String status;
  final String? assignName;
  final String? assignAvatar;

  // Getter để đơn giản hóa việc lấy avatar
  String? get avatar => personAvatar;

  Conversation({
    required this.id,
    required this.pageId,
    required this.pageName,
    this.isFileMessage = false,
    this.pageAvatar,
    required this.personId,
    required this.personName,
    this.personAvatar,
    required this.snippet,
    required this.canReply,
    required this.updatedTime,
    required this.gptStatus,
    required this.isRead,
    required this.type,
    required this.provider,
    required this.status,
    this.assignName,
    this.assignAvatar,
  });

  Conversation copyWith(
      {String? assignName,
      String? assignAvatar,
      String? snippet,
      bool? isRead,
      bool? isFileMessage}) {
    return Conversation(
      id: id,
      pageId: pageId,
      pageName: pageName,
      pageAvatar: pageAvatar,
      personId: personId,
      personName: personName,
      personAvatar: personAvatar,
      snippet: snippet ?? this.snippet,
      canReply: canReply,
      updatedTime: updatedTime,
      gptStatus: gptStatus,
      isRead: isRead ?? this.isRead,
      type: type,
      isFileMessage: isFileMessage ?? this.isFileMessage,
      provider: provider,
      status: status,
      assignName: assignName ?? this.assignName,
      assignAvatar: assignAvatar ?? this.assignAvatar,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    try {
      // Convert timestamp to DateTime
      final timestamp = json['updatedTime'] is int
          ? json['updatedTime']
          : int.tryParse(json['updatedTime']?.toString() ?? '') ??
              DateTime.now().millisecondsSinceEpoch;

      return Conversation(
        id: json['id']?.toString() ?? '',
        pageId: json['pageId']?.toString() ?? '',
        isFileMessage: json["snippet"] == null,
        pageName: json['pageName']?.toString() ?? '',
        pageAvatar: json['pageAvatar']?.toString(),
        personId: json['personId']?.toString() ?? '',
        personName: json['personName']?.toString() ?? '',
        personAvatar: json['personAvatar']?.toString(),
        snippet: json['snippet']?.toString() ?? '',
        canReply: json['canReply'] ?? false,
        updatedTime: DateTime.fromMillisecondsSinceEpoch(timestamp),
        gptStatus: json['gptStatus'] is int ? json['gptStatus'] : 0,
        isRead: json['isRead'] ?? false,
        type: json['type']?.toString() ?? 'MESSAGE',
        provider: json['provider']?.toString() ?? 'ZALO',
        status: json['status']?.toString() ?? '',
        assignName: json['assignName']?.toString(),
        assignAvatar: json['assignAvatar']?.toString(),
      );
    } catch (e) {
      print('Error parsing conversation: $json');
      print('Error: $e');
      rethrow;
    }
  }
}

class MessageNotifier extends StateNotifier<MessageState> {
  final MessageRepository _repository;
  final String? _defaultProvider;
  StreamSubscription? _onChangedListener;
  MessageNotifier(this._repository, [this._defaultProvider])
      : super(MessageState(provider: _defaultProvider));
  @override
  void dispose() {
    _onChangedListener?.cancel();
    super.dispose();
  }

  void reset() {
    state = MessageState(provider: _defaultProvider);
  }

  Future getOData() async {
    final organList = await fetchOrganList();
    // final prefs = await SharedPreferences.getInstance();
    if (organList == null || organList.isEmpty) {
      return Future.error('No organizations found');
    }

    return organList[0];
  }

  void setupFirebaseListener(
    String organizationId,
    BuildContext context,
  ) async {
    final oData = await getOData();
    final oId = oData["id"];

    // Cancel listener cũ nếu có
    await _onChangedListener?.cancel();

    final ref = FirebaseDatabase.instance.ref(
      'root/OrganizationId: $oId',
    );

    _onChangedListener = ref.onValue.listen((event) {
      final snapshot = event.snapshot;
      final data = (snapshot.value ?? {}) as Map;
      bool isDetailUpdate = false;
      final matchedLocation = GoRouter.of(context).state.matchedLocation;
      final fullLocation = GoRouter.of(context).state.fullPath;
      log("Matched location: $matchedLocation");
      log("Data changed: ${data.toString()}");
      if (data.containsKey("CreateOrUpdateConversation")) {
        try {
          final outerKey = data["CreateOrUpdateConversation"]
              .keys
              .first; // "ConversationId: 368f9f83-7015-4306-a50b-7fe27db8c813"
          final key = outerKey.split(': ').first; // "368f9f83-7015-4306-a50b-7fe27db8c813"
          if (key == "ConversationId") {
            final conversationId =
                outerKey.split(': ').last; // "368f9f83-7015-4306-a50b-7fe27db8c813"
            if (fullLocation == "/organization/:organizationId/messages/detail/:conversationId") {
              final Id = matchedLocation.split('/').last;
              if (Id == conversationId) {
                // Nếu đang ở trang chi tiết, cập nhật trạng thái là đã đọc
                isDetailUpdate = true;
              }
            }
            Conversation? roomData = state.conversations.firstWhere((e) => e.id == conversationId);
            // ignore: unnecessary_null_comparison
            if (roomData != null) {
              Conversation updatedConversation = roomData;
              if (data["CreateOrUpdateConversation"][outerKey].containsKey("Message")) {
                updatedConversation = roomData.copyWith(
                    snippet: data["CreateOrUpdateConversation"][outerKey]["Message"],
                    isRead: isDetailUpdate);
                // Cập nhật conversation đã có
              }
              if (data["CreateOrUpdateConversation"][outerKey].containsKey("Attachments")) {
                Attachment? fileAttachment;
                updatedConversation = updatedConversation.copyWith(
                  isFileMessage: true,
                  isRead: isDetailUpdate,
                );
                // Nếu có file đính kèm, parse nó
                // if (dataMess.containsKey("Attachments")) {
                //   final outerKeys = dataMess["Attachments"];
                //   final List<dynamic> decodedList = jsonDecode(outerKeys);

                //   for (final outerKey in decodedList) {
                //     fileAttachment = Attachment.fromJson(outerKey as Map<String, dynamic>);
                //   }
                // }

                updatedConversation = updatedConversation.copyWith();
              }

              // ignore: use_build_context_synchronously
              final currentLocation = GoRouter.of(context).state.matchedLocation;
              print('Current route: $currentLocation');
              updateConversation(updatedConversation, moveToTop: true);
            } else {
              final decoded = jsonDecode(data["CreateOrUpdateConversation"][outerKey].toString());

              // Thêm mới conversation
              final newConversation = Conversation.fromJson(decoded);
              addConversation(newConversation);
            }
            print(data["Message"]);
          }
// Tách ConversationId
        } catch (e) {
          log("message: $e");
          return;
        }
      }

      // final dataMess = data["ConversationId: $conversationId"];
      // if (dataMess is Map && dataMess["ConversationId"] == conversationId) {
      //   // final conversation = Conversation.fromJson(dataMess);
      //   // addConversation(conversation);
      // }
    });
  }

  Future<void> fetchConversations(String organizationId,
      {String? provider, bool forceRefresh = false}) async {
    if (state.isLoading) return;

    final currentProvider = provider ?? _defaultProvider;

    // Reset state nếu là lần fetch đầu tiên hoặc forceRefresh
    if (state.page == 0 || forceRefresh) {
      state = MessageState(
        isLoading: true,
        provider: currentProvider,
      );
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      final response = await _repository.getConversationList(
        organizationId,
        page: forceRefresh ? 0 : state.page,
        integrationAuthId: "",
        provider: currentProvider,
        searchText: '',
      );

      final List<Conversation> conversations =
          (response['content'] as List).map((item) => Conversation.fromJson(item)).toList();

      if (forceRefresh || state.page == 0) {
        state = state.copyWith(
          conversations: conversations,
          isLoading: false,
          hasMore: conversations.length >= 20,
          page: 1,
        );
      } else {
        state = state.copyWith(
          conversations: [...state.conversations, ...conversations],
          isLoading: false,
          hasMore: conversations.length >= 20,
          page: state.page + 1,
        );
      }
    } catch (e) {
      print(e);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateStatusRead(String organizationId, String conversationId) async {
    try {
      // Cập nhật trạng thái đã đọc cho conversation

      Conversation roomData = state.conversations.firstWhere((e) => e.id == conversationId);

      final updatedConversation = roomData.copyWith(
        isRead: true,
      );
      // Cập nhật conversation đã có

      updateConversation(updatedConversation);

      _repository.updateStatusReadRepos(organizationId, conversationId: conversationId);
    } catch (e) {
      print('Error updating status read: $e');
    }
  }

  void clearConversations() {
    state = state.copyWith(
      conversations: [],
      page: 0,
      hasMore: true,
      selectedConversation: null,
    );
  }

  void selectConversation(String conversationId) {
    try {
      final conversation = state.conversations.firstWhere(
        (conv) => conv.id == conversationId,
      );
      state = state.copyWith(selectedConversation: conversation);
    } catch (_) {
      // Không làm gì nếu không tìm thấy conversation
    }
  }

  Future<void> assignConversation(
    String organizationId,
    String conversationId,
    String userId,
    String assignName,
    String? assignAvatar,
  ) async {
    try {
      await _repository.assignConversation(
        organizationId,
        conversationId,
        userId,
      );

      final updatedConversations = state.conversations.map((conv) {
        if (conv.id == conversationId) {
          return conv.copyWith(
            assignName: assignName,
            assignAvatar: assignAvatar,
          );
        }
        return conv;
      }).toList();

      state = state.copyWith(
        conversations: updatedConversations,
        selectedConversation: state.selectedConversation?.copyWith(
          assignName: assignName,
          assignAvatar: assignAvatar,
        ),
      );
    } catch (e) {
      // Handle error
    }
  }

  void updateConversation(Conversation updated, {bool moveToTop = false}) {
    List<Conversation> updatedList;

    if (moveToTop) {
      // Xoá bản cũ & đưa updated lên đầu
      updatedList = [
        updated,
        ...state.conversations.where((c) => c.id != updated.id),
      ];
    } else {
      // Cập nhật tại đúng vị trí cũ
      updatedList = state.conversations.map((c) {
        return c.id == updated.id ? updated : c;
      }).toList();
    }

    final isSelected = state.selectedConversation?.id == updated.id;

    state = state.copyWith(
      conversations: updatedList,
      selectedConversation: isSelected ? updated : state.selectedConversation,
    );
  }

  void addConversation(Conversation newConversation) {
    state = state.copyWith(
      conversations: [newConversation, ...state.conversations],
    );
  }
}
