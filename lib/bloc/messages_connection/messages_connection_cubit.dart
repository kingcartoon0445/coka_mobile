// lib/state/app_cubit.dart

import 'dart:developer';

import 'package:coka/api/api_client.dart';
import 'package:coka/api/repositories/message_repository.dart';
import 'package:coka/bloc/messages_connection/messages_connection_state.dart';
import 'package:coka/models/messages_conection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessagesConnectionCubit extends Cubit<MessagesConnectionState> {
  MessagesConnectionCubit()
      : super(
          MessagesConnectionState.initial(),
        );
  final MessageRepository _messageRepository = MessageRepository(ApiClient());
  Future<void> initialize(
    String organizationId,
  ) async {
    emit(state.copyWith(status: MessagesConnectionStatus.loading));

    try {
      final response = _messageRepository
          .getListMessagesConenction(
        organizationId, // Replace with actual organization ID
        provider: "",
        subscribed: 'messages',
        searchText: '',
      )
          .then((response) {
        if (response['code'] == 0) {
          MessagesConectionResponse messagesConectionResponse =
              MessagesConectionResponse.fromJson(response);
          emit(state.copyWith(
            status: MessagesConnectionStatus.loaded,
            messagesConectionResponse: messagesConectionResponse,
            // initialLocation: initialLocation,
          ));
          return response['data'];
        } else {
          throw Exception('Failed to load messages');
        }
      });
      log(response.toString());
      emit(state.copyWith(
        status: MessagesConnectionStatus.loaded,
        // initialLocation: initialLocation,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MessagesConnectionStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<bool> updateStatisOmniChannel(String organizationId, String id, int status) async {
    emit(state.copyWith(status: MessagesConnectionStatus.loading));

    try {
      final response = await _messageRepository.updateStatisOmniChannelRes(
        id,
        status,
        organizationId,
      );
      if (response['code'] == 0) {
        // MessagesConectionResponse messagesConectionResponse =
        //     MessagesConectionResponse.fromJson(response);
        emit(state.copyWith(
          status: MessagesConnectionStatus.loaded,

          // initialLocation: initialLocation,
        ));
        // log(response.toString());
        // initialize(organizationId);
        emit(state.copyWith(
          status: MessagesConnectionStatus.loaded,
          // initialLocation: initialLocation,
        ));
        return true;
      } else {
        log(response.toString());
        // initialize(organizationId);
        emit(state.copyWith(
          status: MessagesConnectionStatus.loaded,
          // initialLocation: initialLocation,
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        status: MessagesConnectionStatus.error,
        error: e.toString(),
      ));
      return false;
    }
  }
}
