import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/repositories/organization_repository.dart';
import '../api/api_client.dart';
import '../../core/utils/helpers.dart';
// Provider để lưu trữ thông tin tổ chức hiện tại
final currentOrganizationProvider = StateNotifierProvider<CurrentOrganizationNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  return CurrentOrganizationNotifier(OrganizationRepository(ApiClient()));
});

// Provider để lưu trữ danh sách tổ chức
final organizationsListProvider = StateNotifierProvider<OrganizationsListNotifier, AsyncValue<List<dynamic>>>((ref) {
  return OrganizationsListNotifier(OrganizationRepository(ApiClient()));
});

// Provider để kiểm tra quyền của người dùng trong tổ chức hiện tại
final isAdminOrOwnerProvider = Provider<bool>((ref) {
  final organizationState = ref.watch(currentOrganizationProvider);
  
  return organizationState.when(
    data: (organization) {
      if (organization == null) return false;
      final type = organization['type']?.toString().toUpperCase() ?? 'MEMBER';
      return type == 'ADMIN' || type == 'OWNER';
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

// Provider để lấy vai trò của người dùng trong tổ chức hiện tại
final userRoleProvider = Provider<String>((ref) {
  final organizationState = ref.watch(currentOrganizationProvider);
  
  return organizationState.when(
    data: (organization) {
      if (organization == null) return 'MEMBER';
      return organization['type']?.toString().toUpperCase() ?? 'MEMBER';
    },
    loading: () => 'MEMBER',
    error: (_, __) => 'MEMBER',
  );
});

class CurrentOrganizationNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final OrganizationRepository _organizationRepository;
  String? _currentOrganizationId;

  CurrentOrganizationNotifier(this._organizationRepository) 
      : super(const AsyncValue.loading());

  Future<void> loadOrganization(String organizationId) async {
    // Nếu ID tổ chức giống với ID hiện tại và đã có dữ liệu, không cần tải lại
    if (_currentOrganizationId == organizationId && state.value != null) {
      return;
    }

    try {
      state = const AsyncValue.loading();
      _currentOrganizationId = organizationId;
      
      // Lấy danh sách tổ chức trước
      final response = await _organizationRepository.getOrganizations();
      
      if (Helpers.isResponseSuccess(response)) {
        final organizations = response['content'] as List<dynamic>;
        
        // Tìm tổ chức hiện tại trong danh sách
        final currentOrg = organizations.firstWhere(
          (org) => org['id'] == organizationId,
          orElse: () => null,
        );
        
        if (currentOrg != null) {
          state = AsyncValue.data(currentOrg);
        } else {
          // Nếu không tìm thấy, cố gắng lấy chi tiết tổ chức qua API riêng
          final detailResponse = await _organizationRepository.getOrganizationDetail(organizationId);
          if (detailResponse['code'] == 0) {
            state = AsyncValue.data(detailResponse['content']);
          } else {
            state = AsyncValue.error(
              'Không tìm thấy thông tin tổ chức',
              StackTrace.current,
            );
          }
        }
      } else {
        state = AsyncValue.error(
          response['message'] ?? 'Lỗi không xác định',
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  String? get currentOrganizationId => _currentOrganizationId;
}

class OrganizationsListNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final OrganizationRepository _organizationRepository;
  bool _isLoaded = false;

  OrganizationsListNotifier(this._organizationRepository) 
      : super(const AsyncValue.loading());

  Future<void> loadOrganizations() async {
    // Nếu đã tải danh sách rồi, không cần tải lại
    if (_isLoaded && state.value != null && state.value!.isNotEmpty) {
      return;
    }

    try {
      state = const AsyncValue.loading();
      
      final response = await _organizationRepository.getOrganizations();
      
      if (Helpers.isResponseSuccess(response)) {
        final organizations = response['content'] as List<dynamic>;
        state = AsyncValue.data(organizations);
        _isLoaded = true;
      } else {
        state = AsyncValue.error(
          response['message'] ?? 'Lỗi không xác định',
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  // Làm mới danh sách tổ chức (ví dụ sau khi tạo tổ chức mới)
  Future<void> refresh() async {
    _isLoaded = false;
    await loadOrganizations();
  }
} 