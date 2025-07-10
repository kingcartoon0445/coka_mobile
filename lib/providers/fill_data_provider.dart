import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/api/repositories/fill_data_repository.dart';
import 'package:coka/models/workspace_data.dart';
import 'package:coka/providers/app_providers.dart';

// State class for Fill Data
class FillDataState {
  final List<WorkspaceData> workspaces;
  final bool isLoading;
  final String? error;

  const FillDataState({
    this.workspaces = const [],
    this.isLoading = false,
    this.error,
  });

  FillDataState copyWith({
    List<WorkspaceData>? workspaces,
    bool? isLoading,
    String? error,
  }) {
    return FillDataState(
      workspaces: workspaces ?? this.workspaces,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Note: FillDataRepository provider is now defined in app_providers.dart

// Provider for Fill Data State
class FillDataNotifier extends StateNotifier<FillDataState> {
  final FillDataRepository _repository;

  FillDataNotifier(this._repository) : super(const FillDataState());

  /// Tải danh sách workspace
  Future<void> loadWorkspaces(String orgId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.getFillDataList(orgId);
      
      if (response.isSuccess) {
        state = state.copyWith(
          workspaces: response.data ?? [],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: response.message,
          isLoading: false,
        );
        _showErrorToast(response.message);
      }
    } catch (error) {
      final errorMessage = 'Có lỗi xảy ra: $error';
      state = state.copyWith(
        error: errorMessage,
        isLoading: false,
      );
      _showErrorToast(errorMessage);
    }
  }

  /// Cập nhật trạng thái workspace
  Future<void> updateWorkspaceStatus(String orgId, String id, int status) async {
    try {
      final response = await _repository.updateFillDataStatus(orgId, id, status);
      
      if (response.isSuccess) {
        // Tải lại danh sách sau khi cập nhật thành công
        await loadWorkspaces(orgId);
        // TODO: Show success message using your preferred toast/snackbar method
        print('Cập nhật trạng thái thành công');
      } else {
        _showErrorToast(response.message);
      }
    } catch (error) {
      _showErrorToast('Có lỗi xảy ra khi cập nhật trạng thái: $error');
    }
  }

  /// Làm mới dữ liệu
  Future<void> refresh(String orgId) async {
    await loadWorkspaces(orgId);
  }

  void _showErrorToast(String message) {
    // TODO: Implement toast/snackbar showing using your preferred method
    print('Error: $message');
  }
}

// Provider cho Fill Data State Notifier
final fillDataProvider = StateNotifierProvider<FillDataNotifier, FillDataState>((ref) {
  final repository = ref.read(fillDataRepositoryProvider);
  return FillDataNotifier(repository);
}); 