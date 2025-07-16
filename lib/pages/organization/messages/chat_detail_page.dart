import 'dart:async';
import 'dart:io';

import 'package:coka/pages/organization/messages/widgets/download_file.dart';
import 'package:coka/pages/organization/messages/widgets/full_image.dart';
import 'package:coka/shared/widgets/avatar_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/assign_to_bottomsheet.dart';
import '../../../shared/widgets/loading_indicator.dart';
import './models/message_model.dart';
import './state/chat_state.dart';
import './state/message_state.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final String organizationId;
  final String conversationId;

  const ChatDetailPage({
    super.key,
    required this.organizationId,
    required this.conversationId,
  });

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingMore = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadFileName;
  StreamSubscription? onChangedListener;
  @override
  void initState() {
    super.initState();
    // AuthRepository(ApiClient()).getProfile();
    Future(() {
      if (mounted) {
        _loadInitialMessages();
      }
    });
    ref.read(chatProvider.notifier).setupFirebaseListener(
          widget.organizationId,
          widget.conversationId,
        );
    _setupScrollListener();
  }

  void _loadInitialMessages() {
    ref.read(chatProvider.notifier).loadMessages(
          widget.organizationId,
          widget.conversationId,
          refresh: true,
        );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMoreMessages();
      }
    });
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    await ref.read(chatProvider.notifier).loadMessages(
          widget.organizationId,
          widget.conversationId,
        );

    _isLoadingMore = false;
  }

  void _clearInput() {
    // Unfocus để đảm bảo keyboard state được reset
    FocusScope.of(context).unfocus();

    // Clear input
    _messageController.clear();

    // Force rebuild để đảm bảo UI update
    if (mounted) {
      setState(() {});
    }

    print('Input cleared, current text: "${_messageController.text}"');
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    print('Sending message: $message');
    print('Before clear: ${_messageController.text}');

    // Clear input ngay lập tức để tránh gửi trùng
    _clearInput();

    print('After clear: ${_messageController.text}');

    try {
      await ref.read(chatProvider.notifier).sendMessage(
            widget.organizationId,
            widget.conversationId,
            message,
          );
      print('Message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
      // Khôi phục lại message nếu gửi thất bại
      _messageController.text = message;

      // Hiển thị thông báo lỗi nếu có lỗi xảy ra
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi tin nhắn: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // File/Image handling methods với optimistic UI
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _handleFileSelected(image.path, isImage: true, fileName: image.name);
      }
    } catch (e) {
      _showErrorSnackBar('Không thể chọn ảnh: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _handleFileSelected(image.path, isImage: true, fileName: image.name);
      }
    } catch (e) {
      _showErrorSnackBar('Không thể chụp ảnh: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'], // Support như web input
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        await _handleFileSelected(file.path!, isImage: false, fileName: file.name);
      }
    } catch (e) {
      _showErrorSnackBar('Không thể chọn file: $e');
    }
  }

  // Xử lý file được chọn với optimistic UI (theo logic web)
  Future<void> _handleFileSelected(String filePath,
      {required bool isImage, required String fileName}) async {
    if (_isUploading) return;

    final file = File(filePath);
    final currentMessage = _messageController.text.trim();

    // Detect file type theo logic web: dựa vào MIME type thay vì extension
    String? mimeType = _getMimeTypeFromFile(file);
    final bool isActuallyImage = mimeType?.startsWith('image/') ?? false;

    // Clear input ngay lập tức
    _clearInput();

    // Tạo local message ngay lập tức (theo logic web)
    final localMessage = _createLocalMessage(
      content: currentMessage,

      filePath: filePath,
      fileName: fileName,
      isImage: isActuallyImage, // Use detected MIME type
      mimeType: mimeType,
    );

    // Hiển thị tin nhắn local ngay lập tức (optimistic UI)
    ref.read(chatProvider.notifier).addLocalMessage(localMessage);

    // Bắt đầu upload UI
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadFileName = fileName;
    });

    try {
      // Gửi lên server riêng biệt (không tạo local message nữa)
      if (isActuallyImage) {
        await ref.read(chatProvider.notifier).sendImageToServer(
              widget.organizationId,
              widget.conversationId,
              XFile(filePath),
              localMessage.localId!,
              textMessage: currentMessage.isNotEmpty ? currentMessage : null,
            );
      } else {
        await ref.read(chatProvider.notifier).sendFileToServer(
              widget.organizationId,
              widget.conversationId,
              file,
              localMessage.localId!,
              textMessage: currentMessage.isNotEmpty ? currentMessage : null,
            );
      }
    } catch (e) {
      _showErrorSnackBar(isActuallyImage ? 'Không thể gửi ảnh: $e' : 'Không thể gửi file: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _uploadFileName = null;
        });
      }
    }
  }

  // Helper method để detect MIME type từ file
  String? _getMimeTypeFromFile(File file) {
    try {
      final extension = file.path.split('.').last.toLowerCase();
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          return 'image/jpeg';
        case 'png':
          return 'image/png';
        case 'gif':
          return 'image/gif';
        case 'webp':
          return 'image/webp';
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
    } catch (e) {
      return null;
    }
  }

  // Tạo tin nhắn local theo format web
  Message _createLocalMessage({
    required String content,
    required String filePath,
    required String fileName,
    required bool isImage,
    String? mimeType,
  }) {
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    if (isImage) {
      // ẢNH: Lưu vào attachments (như web)
      return Message(
        id: '', // Không có id server
        localId: localId,
        conversationId: widget.conversationId,
        messageId: localId,
        from: '124662217400086', // Page ID
        fromName: 'You',
        to: '',

        toName: '',
        message: content,
        isFromMe: true,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isGpt: false,
        type: 'MESSAGE',
        fullName: 'You',
        status: 0,
        sending: true,
        attachments: [
          Attachment(
            type: 'image',
            url: 'file://$filePath', // Local file URL
            name: fileName,
            payload: {
              'url': 'file://$filePath',
              'name': fileName,
            },
          ),
        ],
      );
    } else {
      // FILE KHÁC: Lưu vào fileAttachment (như web)
      return Message(
        id: '', // Không có id server
        localId: localId,
        conversationId: widget.conversationId,
        messageId: localId,
        from: '124662217400086', // Page ID
        fromName: 'You',
        to: '',
        isFromMe: true,
        toName: '',
        message: content,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isGpt: false,
        type: 'MESSAGE',
        fullName: 'You',
        status: 0,
        sending: true,
        fileAttachment: FileAttachment(
          name: fileName,
          type: mimeType ?? 'application/octet-stream',
          size: File(filePath).lengthSync(),
          url: 'file://$filePath', // Local file URL
        ),
      );
    }
  }

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

  void _cancelUpload() {
    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
      _uploadFileName = null;
    });
    // TODO: Implement actual upload cancellation logic
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAssignBottomSheet(Conversation conversation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => AssignToBottomSheet(
        currentAssignedId: conversation.assignName, // TODO: Get actual assigned ID
        organizationId: widget.organizationId,
        workspaceId: 'temp_workspace_id', // TODO: Get actual workspace ID
        onSelected: (assignData) {
          _showConfirmAssignDialog(assignData);
        },
      ),
    );
  }

  void _showConfirmAssignDialog(Map<String, dynamic> assignData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chuyển phụ trách?'),
        content: const Text('Bạn có chắc muốn chuyển cuộc trò chuyện này cho người khác?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _assignConversation(assignData);
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignConversation(Map<String, dynamic> assignData) async {
    try {
      // TODO: Implement assign conversation logic
      _showSuccessSnackBar('Đã chuyển phụ trách thành công');
    } catch (e) {
      _showErrorSnackBar('Lỗi chuyển phụ trách: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Tìm conversation trong các provider
    final allConversations = ref.watch(allMessageProvider).conversations;
    final zaloConversations = ref.watch(zaloMessageProvider).conversations;
    final facebookConversations = ref.watch(facebookMessageProvider).conversations;

    Conversation? foundConversation;

    // Tìm trong Zalo conversations
    try {
      foundConversation = zaloConversations.firstWhere(
        (conv) => conv.id == widget.conversationId,
      );
    } catch (_) {
      // Tìm trong Facebook conversations
      try {
        foundConversation = facebookConversations.firstWhere(
          (conv) => conv.id == widget.conversationId,
        );
      } catch (_) {
        // Tìm trong all conversations
        try {
          foundConversation = allConversations.firstWhere(
            (conv) => conv.id == widget.conversationId,
          );
        } catch (_) {
          // Không tìm thấy conversation
        }
      }
    }

    // Nếu không tìm thấy conversation, hiển thị thông báo lỗi
    if (foundConversation == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Chi tiết tin nhắn'),
        ),
        body: const Center(
          child: Text(
            'Không tìm thấy cuộc trò chuyện',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    final conversation = foundConversation;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            AppAvatar(
              imageUrl: conversation.personAvatar,
              fallbackText: conversation.personName,
              size: 40,
              shape: AvatarShape.circle,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.personName,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    conversation.pageName,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Nút chuyển phụ trách
          IconButton(
            onPressed: () => _showAssignBottomSheet(conversation),
            tooltip: 'Chuyển phụ trách',
            icon: const Icon(Icons.swap_horiz),
          ),
          // Menu khác
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'info':
                  // TODO: Navigate to customer info
                  break;
                case 'block':
                  // TODO: Block customer
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text('Thông tin khách hàng'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block),
                    SizedBox(width: 8),
                    Text('Chặn'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Upload progress indicator
          if (_isUploading)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: _uploadProgress > 0 ? _uploadProgress : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đang tải lên${_uploadFileName != null ? ': $_uploadFileName' : '...'}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (_uploadProgress > 0)
                          Text(
                            '${(_uploadProgress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _cancelUpload,
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Hủy tải lên',
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.5, end: 0),

          Expanded(
            child: chatState.isLoading && chatState.messages.isEmpty
                ? const Center(child: LoadingIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: chatState.messages.length + (chatState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatState.messages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: LoadingIndicator(),
                          ),
                        );
                      }

                      final message = chatState.messages[index];
                      final previousMessage = index < chatState.messages.length - 1
                          ? chatState.messages[index + 1]
                          : null;
                      final isFirstInTurn =
                          previousMessage == null || previousMessage.from != message.from;
                      final showAvatar = isFirstInTurn;

                      if (index == chatState.messages.length - 1) {
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      'Bắt đầu cuộc trò chuyện',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).hintColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                                ],
                              ),
                            ),
                            _MessageBubble(
                              message: message,
                              showAvatar: showAvatar,
                              isFirstInTurn: isFirstInTurn,
                              organizationId: widget.organizationId,
                              conversationId: widget.conversationId,
                            ),
                          ],
                        );
                      }

                      return _MessageBubble(
                        message: message,
                        showAvatar: showAvatar,
                        isFirstInTurn: isFirstInTurn,
                        organizationId: widget.organizationId,
                        conversationId: widget.conversationId,
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Nút gửi hình ảnh với PopupMenu (camera/gallery)
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.image,
                        color: (chatState.isSending || _isUploading)
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      enabled: !chatState.isSending && !_isUploading,
                      tooltip: 'Gửi hình ảnh',
                      onSelected: (String value) {
                        switch (value) {
                          case 'camera':
                            _pickImageFromCamera();
                            break;
                          case 'gallery':
                            _pickImageFromGallery();
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'camera',
                          child: Row(
                            children: [
                              Icon(Icons.camera_alt),
                              SizedBox(width: 8),
                              Text('Chụp ảnh'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'gallery',
                          child: Row(
                            children: [
                              Icon(Icons.photo_library),
                              SizedBox(width: 8),
                              Text('Thư viện'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Nút gửi file
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      onPressed: (chatState.isSending || _isUploading) ? null : _pickFile,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Gửi file đính kèm',
                      icon: Icon(
                        Icons.attach_file,
                        color: (chatState.isSending || _isUploading)
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Input field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 36,
                        maxHeight: 100,
                      ),
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: null,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          hintText: 'Nhập nội dung...',
                          hintStyle: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textInputAction: TextInputAction.newline,
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !chatState.isSending && !_isUploading,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Nút gửi tin nhắn
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      onPressed: (chatState.isSending || _isUploading) ? null : _sendMessage,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Gửi tin nhắn',
                      icon: (chatState.isSending || _isUploading)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.send,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;
  final bool isFirstInTurn;
  final String organizationId;
  final String conversationId;

  const _MessageBubble({
    required this.message,
    this.showAvatar = true,
    this.isFirstInTurn = true,
    required this.organizationId,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context) {
    const bubbleColor = Color(0xFFF1F5F9);
    const textColor = Colors.black;

    return Consumer(
      builder: (context, ref, child) {
        final chatState = ref.watch(chatProvider);

        // Check if this is local message (theo logic web)
        final isLocalMessage = message.localId != null && message.id.isEmpty;
        final isFromPage = message.isFromMe; // ID của page

        // Determine error state
        final hasError = chatState.messageErrors.containsKey(message.localId ?? message.id);
        final errorMessage =
            hasError ? chatState.messageErrors[message.localId ?? message.id] : null;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Column(
            crossAxisAlignment: isFromPage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Hiển thị tên người gửi khi isFirstInTurn
              if (isFirstInTurn) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    isFromPage
                        ? (message.fullName.isNotEmpty ? message.fullName : 'You')
                        : message.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],

              // Nội dung tin nhắn với avatar
              Row(
                mainAxisAlignment: isFromPage ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar bên trái (cho tin nhắn từ khách hàng)
                  if (!isFromPage) ...[
                    if (showAvatar)
                      AppAvatar(
                        imageUrl: message.senderAvatar,
                        fallbackText: message.senderName,
                        size: 44,
                        shape: AvatarShape.circle,
                      ).animate().fadeIn(duration: 300.ms)
                    else
                      const SizedBox(width: 44),
                    const SizedBox(width: 8),
                  ],

                  // Message bubble
                  Flexible(
                    child: Column(
                      crossAxisAlignment:
                          isFromPage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: (message.attachments?.isNotEmpty == true ||
                                            message.fileAttachment != null) &&
                                        message.content.isEmpty
                                    ? const EdgeInsets.all(8)
                                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: bubbleColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Text content
                                    if (message.content.isNotEmpty)
                                      Text(
                                        message.content,
                                        style: const TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          height: 1.25,
                                        ),
                                      ),

                                    // Render attachments từ server (ảnh)
                                    if (message.attachments?.isNotEmpty == true) ...[
                                      if (message.content.isNotEmpty) const SizedBox(height: 8),
                                      ...message.attachments!.map((attachment) {
                                        if (attachment.type.toLowerCase() == 'sticker' ||
                                            attachment.type.toLowerCase().contains('image')) {
                                          return _buildImageWidget(
                                            attachment.url,
                                            attachment.type,
                                            context,
                                            isLocal: isLocalMessage,
                                          );
                                        }
                                        return _buildFileWidget(
                                          attachment.payload!["name"] ?? 'File đính kèm',
                                          () {
                                            downloadFile(
                                              context,
                                              attachment.url,
                                              attachment.payload!["name"] ?? "coka_file",
                                            );
                                            // TODO: Open file
                                          },
                                          context,
                                          isLocal: isLocalMessage,
                                        );
                                      }),
                                    ],

                                    // Render file attachment (file khác - theo logic web)
                                    if (message.fileAttachment != null) ...[
                                      if (message.content.isNotEmpty) const SizedBox(height: 8),
                                      _buildFileWidget(
                                        message.fileAttachment!.name,
                                        () {
                                          // TODO: Open local file
                                        },
                                        context,
                                        isLocal: isLocalMessage,
                                      ),
                                    ],
                                  ],
                                ),
                              ).animate().fadeIn(duration: 300.ms).slideX(
                                    begin: isFromPage ? -0.3 : 0.3,
                                    end: 0,
                                    duration: 300.ms,
                                    curve: Curves.easeOutCubic,
                                  ),
                            ),

                            // Status icon cho tin nhắn từ page (theo logic web)
                            if (isFromPage)
                              Padding(
                                padding: const EdgeInsets.only(left: 8, bottom: 4),
                                child: Icon(
                                  // Local/sending: schedule icon, sent: done_all (theo logic web)
                                  (isLocalMessage || message.sending)
                                      ? Icons.schedule // Đang gửi hoặc local
                                      : Icons.done_all, // Đã gửi
                                  size: 16,
                                  color: (isLocalMessage || message.sending)
                                      ? Colors.grey
                                      : Theme.of(context).primaryColor,
                                ),
                              ),

                            // Error icon
                            if (hasError)
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 4),
                                child: GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Lỗi: ${errorMessage ?? 'Không thể gửi tin nhắn'}'),
                                        action: SnackBarAction(
                                          label: 'Gửi lại',
                                          onPressed: () {
                                            final chatNotifier = ref.read(chatProvider.notifier);

                                            // Retry message based on type
                                            if (message.attachments?.isNotEmpty == true) {
                                              // Retry image - TODO: implement retry logic for images
                                            } else if (message.fileAttachment != null) {
                                              // Retry file - TODO: implement retry logic for files
                                            } else {
                                              // Retry text message
                                              chatNotifier.resendMessage(
                                                organizationId,
                                                conversationId,
                                                message.localId ?? message.id,
                                                message.content,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Avatar bên phải (cho tin nhắn từ page)
                  if (isFromPage) ...[
                    const SizedBox(width: 8),
                    if (showAvatar)
                      AppAvatar(
                        imageUrl: message.senderAvatar,
                        fallbackText: message.senderName,
                        size: 44,
                        shape: AvatarShape.circle,
                      ).animate().fadeIn(duration: 300.ms)
                    else
                      const SizedBox(width: 44),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(String url, String type, BuildContext context, {bool isLocal = false}) {
    final isSticker = type.toLowerCase() == 'sticker';
    final width = isSticker ? 130.0 : 200.0;
    final height = isSticker ? 130.0 : 200.0;

    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Xử lý file:// URLs cho local files vs server URLs (theo logic web)
          url.startsWith('file://')
              ? Image.file(
                  File(url.replaceFirst('file://', '')),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImageErrorWidget(context);
                  },
                )
              : Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImageErrorWidget(context);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),

          // Loading overlay cho local images
          if (isLocal)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullScreenImage(imageUrl: url),
                  ),
                );
                // TODO: Implement image viewer
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildImageErrorWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: 40,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 8),
          Text(
            'Hình ảnh không khả dụng',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileWidget(String fileName, VoidCallback onTap, BuildContext context,
      {bool isLocal = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: isLocal
              ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        icon: Icon(
          Icons.attachment,
          color: isLocal ? Colors.grey : null,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                fileName,
                style: TextStyle(
                  fontSize: 13,
                  color: isLocal ? Colors.grey : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isLocal) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
