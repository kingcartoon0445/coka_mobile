// lib/state/app_cubit.dart

import 'package:coka/api/api_client.dart';
import 'package:coka/paths.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(AppState.initial());

  Future<void> initialize() async {
    emit(state.copyWith(status: AppStatus.loading));

    try {
      final token = await ApiClient.storage.read(key: 'access_token');
      final orgId = await ApiClient.storage.read(key: 'default_organization_id');

      final initialLocation =
          token != null ? AppPaths.organization(orgId ?? 'default') : AppPaths.login;

      emit(state.copyWith(
        status: AppStatus.loaded,
        initialLocation: initialLocation,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AppStatus.error,
        error: e.toString(),
      ));
    }
  }
}
