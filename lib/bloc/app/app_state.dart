// lib/state/app_state.dart

import 'package:equatable/equatable.dart';

enum AppStatus { initial, loading, loaded, error }

class AppState extends Equatable {
  final AppStatus status;
  final String initialLocation;
  final String? error;

  const AppState({
    required this.initialLocation,
    this.status = AppStatus.initial,
    this.error,
  });

  factory AppState.initial() => const AppState(
        status: AppStatus.initial,
        initialLocation: '/',
      );

  AppState copyWith({
    AppStatus? status,
    String? initialLocation,
    String? error,
  }) {
    return AppState(
      status: status ?? this.status,
      initialLocation: initialLocation ?? this.initialLocation,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, initialLocation, error];
}
