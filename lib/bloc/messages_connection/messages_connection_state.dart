// lib/state/app_state.dart

import 'package:coka/models/messages_conection.dart';
import 'package:equatable/equatable.dart';

enum MessagesConnectionStatus { initial, loading, loaded, error }

class MessagesConnectionState extends Equatable {
  final MessagesConnectionStatus status;
  final MessagesConectionResponse? messagesConectionResponse;
  final String? error;

  const MessagesConnectionState({
    required this.messagesConectionResponse,
    this.status = MessagesConnectionStatus.initial,
    this.error,
  });

  factory MessagesConnectionState.initial() => const MessagesConnectionState(
        status: MessagesConnectionStatus.initial,
        messagesConectionResponse: null,
        error: null,
      );

  MessagesConnectionState copyWith({
    MessagesConnectionStatus? status,
    MessagesConectionResponse? messagesConectionResponse,
    String? error,
  }) {
    return MessagesConnectionState(
      status: status ?? this.status,
      messagesConectionResponse: messagesConectionResponse ?? this.messagesConectionResponse,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, messagesConectionResponse, error];
}
