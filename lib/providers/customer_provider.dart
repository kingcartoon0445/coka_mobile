import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/repositories/customer_repository.dart';
import '../api/api_client.dart';
import '../core/utils/helpers.dart';
import 'package:dio/dio.dart';

final customerListProvider = StateNotifierProvider<CustomerListNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return CustomerListNotifier(CustomerRepository(ApiClient()));
});

class CustomerListNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final CustomerRepository _repository;
  String? _lastOrganizationId;
  String? _lastWorkspaceId;
  Map<String, String>? _lastQueryParams;

  CustomerListNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadCustomers(String organizationId, String workspaceId,
      Map<String, String> queryParams, {bool forceRefresh = false}) async {
    if (!mounted) return;

    // Tạo bản copy của params để so sánh cache (không bao gồm offset)
    final paramsForCache = Map<String, String>.from(queryParams);
    paramsForCache.remove('offset'); // Loại trừ offset khỏi cache comparison
    
    // Chỉ skip cache nếu không phải force refresh và params giống nhau
    if (!forceRefresh && 
        _lastOrganizationId == organizationId &&
        _lastWorkspaceId == workspaceId &&
        _mapEquals(_lastQueryParams, paramsForCache) &&
        state.hasValue) {
      print('CustomerListProvider: Using cached data, skipping API call');
      return;
    }

    try {
      // Chỉ show loading nếu không có data hoặc force refresh từ đầu
      final offset = int.tryParse(queryParams['offset'] ?? '0') ?? 0;
      if (offset == 0 || forceRefresh || !state.hasValue) {
        state = const AsyncValue.loading();
      }

      print('CustomerListProvider: Making API call with params: $queryParams');
      final response = await _repository.getCustomers(
          organizationId, workspaceId,
          queryParameters: queryParams);
      
      if (!mounted) return;
      
      final items = response['content'] as List;

      // Cập nhật cache info
      _lastOrganizationId = organizationId;
      _lastWorkspaceId = workspaceId;
      _lastQueryParams = Map<String, String>.from(paramsForCache);

      print('CustomerListProvider: Loaded ${items.length} customers for offset: $offset');
      
      if (mounted) {
        state = AsyncValue.data(items.cast<Map<String, dynamic>>());
      }
    } catch (e, stack) {
      print('CustomerListProvider: Error loading customers: $e');
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  // Method để force refresh danh sách customers
  Future<void> refreshCustomers(String organizationId, String workspaceId,
      Map<String, String> queryParams) async {
    await loadCustomers(organizationId, workspaceId, queryParams, forceRefresh: true);
  }

  // Method để clear cache khi cần refresh
  void clearCache() {
    _lastOrganizationId = null;
    _lastWorkspaceId = null;
    _lastQueryParams = null;
  }

  bool _mapEquals(Map<String, String>? map1, Map<String, String>? map2) {
    if (map1 == null || map2 == null) return map1 == map2;
    if (map1.length != map2.length) return false;
    return map1.entries.every((e) => map2[e.key] == e.value);
  }

  void addCustomer(Map<String, dynamic> customer) {
    state.whenData((customers) {
      state = AsyncValue.data([customer, ...customers]);
    });
  }

  void removeCustomer(String customerId) {
    state.whenData((customers) {
      state = AsyncValue.data(
        customers.where((c) => c['id'] != customerId).toList(),
      );
    });
  }

  void updateCustomer(Map<String, dynamic> updatedCustomer) {
    state.whenData((customers) {
      final index =
          customers.indexWhere((c) => c['id'] == updatedCustomer['id']);
      if (index != -1) {
        final newList = [...customers];
        newList[index] = updatedCustomer;
        state = AsyncValue.data(newList);
      }
    });
  }
}

final customerDetailProvider = StateNotifierProvider.family<
    CustomerDetailNotifier,
    AsyncValue<Map<String, dynamic>?>,
    String>((ref, customerId) {
  return CustomerDetailNotifier(
    customerRepository: CustomerRepository(ApiClient()),
    customerId: customerId,
    ref: ref,
  );
});

final customerJourneyProvider = StateNotifierProvider.family<
    CustomerJourneyNotifier,
    AsyncValue<List<dynamic>>,
    String>((ref, customerId) {
  return CustomerJourneyNotifier(
    customerRepository: CustomerRepository(ApiClient()),
    customerId: customerId,
  );
});

class CustomerDetailNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final CustomerRepository _customerRepository;
  final String _customerId;
  final Ref _ref;

  CustomerDetailNotifier({
    required CustomerRepository customerRepository,
    required String customerId,
    required Ref ref,
  })  : _customerRepository = customerRepository,
        _customerId = customerId,
        _ref = ref,
        super(const AsyncValue.loading());

  Future<Map<String, dynamic>?> loadCustomerDetail(
    String organizationId,
    String workspaceId, {
    bool skipLoading = false,
  }) async {
    try {
      if (!skipLoading) {
        state = const AsyncValue.loading();
      }
      final response = await _customerRepository.getCustomerDetail(
        organizationId,
        workspaceId,
        _customerId,
      );
      
      // Kiểm tra xem có customer data trả về không
      if (response['content'] == null) {
        // Trường hợp API trả về mã lỗi != 200
        if (response['code'] != null && response['code'] != 200) {
          final errorMessage = response['message'] as String? ?? 'Đã xảy ra lỗi';
          state = AsyncValue.error(errorMessage, StackTrace.current);
          return null;
        }
      }
      
      final customerData = response['content'] as Map<String, dynamic>;
      state = AsyncValue.data(customerData);
      return customerData;
    } catch (error, stackTrace) {
      // Debug 
      print('Error in loadCustomerDetail: $error');
      
      // Trường hợp lỗi từ Dio
      if (error is DioException) {
        print('DioException status code: ${error.response?.statusCode}');
        print('DioException response data: ${error.response?.data}');
        
        final responseData = error.response?.data;
        if (responseData is Map<String, dynamic> && responseData['message'] != null) {
          final errorMessage = responseData['message'] as String;
          state = AsyncValue.error(errorMessage, stackTrace);
          return null;
        }
      }
      
      // Mặc định nếu không xác định được message lỗi
      state = AsyncValue.error('Không thể tải thông tin khách hàng', stackTrace);
      return null;
    }
  }

  Future<Map<String, dynamic>?> assignToCustomer(
    String organizationId,
    String workspaceId,
    Map<String, dynamic> assignToData,
  ) async {
    try {
      final response = await _customerRepository.assignToCustomer(
        organizationId,
        workspaceId,
        _customerId,
        assignToData,
      );
      
      // Kiểm tra mã trạng thái từ API
      if (!Helpers.isResponseSuccess(response)) {
        final errorMessage = response['message'] as String? ?? 'Đã xảy ra lỗi khi chuyển phụ trách';
        throw errorMessage;
      }

      // Load lại customer detail
      final customerData = await loadCustomerDetail(organizationId, workspaceId, skipLoading: true);

      // Load lại journey list
      _ref.invalidate(customerJourneyProvider(_customerId));
      await _ref
          .read(customerJourneyProvider(_customerId).notifier)
          .loadJourneyList(organizationId, workspaceId);

      // Refresh customer list một lần duy nhất
      _ref.read(customerListProvider.notifier).clearCache();
      
      // Notify về assignment change để trigger refresh
      _ref.read(customerAssignmentRefreshProvider.notifier).notifyAssignmentChanged();
          
      return customerData;
    } catch (error) {
      // Debug
      print('Error in assignToCustomer: $error');
      
      // Trường hợp lỗi từ Dio
      if (error is DioException) {
        print('DioException status code: ${error.response?.statusCode}');
        print('DioException response data: ${error.response?.data}');
        
        final responseData = error.response?.data;
        if (responseData is Map<String, dynamic> && responseData['message'] != null) {
          throw responseData['message'] as String;
        }
      }
      
      // Nếu là String (đã xử lý ở trên) thì throw trực tiếp
      if (error is String) {
        rethrow;
      }
      
      // Trường hợp lỗi khác
      throw 'Lỗi khi chuyển phụ trách';
    }
  }

  Future<Map<String, dynamic>?> assignToCustomerV2(
    String organizationId,
    String workspaceId,
    Map<String, dynamic> assignToData,
  ) async {
    try {
      final response = await _customerRepository.assignToCustomerV2(
        organizationId,
        workspaceId,
        _customerId,
        assignToData,
      );
      
      // Kiểm tra mã trạng thái từ API - assignToCustomerV2 trả về code 0 khi thành công
      if (!Helpers.isResponseSuccess(response)) {
        final errorMessage = response['message'] as String? ?? 'Đã xảy ra lỗi khi chuyển phụ trách';
        throw errorMessage;
      }

      print('assignToCustomerV2: API call successful, response: $response');

      // Load lại customer detail
      final customerData = await loadCustomerDetail(organizationId, workspaceId, skipLoading: true);
      print('assignToCustomerV2: Customer detail reloaded successfully');

      // Load lại journey list
      _ref.invalidate(customerJourneyProvider(_customerId));
      await _ref
          .read(customerJourneyProvider(_customerId).notifier)
          .loadJourneyList(organizationId, workspaceId);
      print('assignToCustomerV2: Journey list reloaded successfully');

      // Refresh customer list một lần duy nhất
      _ref.read(customerListProvider.notifier).clearCache();
      
      // Notify về assignment change để trigger refresh
      _ref.read(customerAssignmentRefreshProvider.notifier).notifyAssignmentChanged();
      
      print('assignToCustomerV2: Assignment completed successfully');
      return customerData;
    } catch (error) {
      // Debug
      print('Error in assignToCustomerV2: $error');
      
      // Trường hợp lỗi từ Dio
      if (error is DioException) {
        print('DioException status code: ${error.response?.statusCode}');
        print('DioException response data: ${error.response?.data}');
        
        final responseData = error.response?.data;
        if (responseData is Map<String, dynamic> && responseData['message'] != null) {
          throw responseData['message'] as String;
        }
      }
      
      // Nếu là String (đã xử lý ở trên) thì throw trực tiếp
      if (error is String) {
        rethrow;
      }
      
      // Trường hợp lỗi khác
      throw 'Lỗi khi chuyển phụ trách';
    }
  }

  Future<Map<String, dynamic>?> updateCustomer(
    String organizationId,
    String workspaceId,
    FormData formData,
  ) async {
    try {
      final response = await _customerRepository.updateCustomer(
        organizationId,
        workspaceId,
        _customerId,
        formData,
      );
      
      // Kiểm tra mã trạng thái từ API - API trả về code 0 khi thành công
      if (!Helpers.isResponseSuccess(response)) {
        final errorMessage = response['message'] as String? ?? 'Đã xảy ra lỗi khi cập nhật khách hàng';
        throw errorMessage;
      }

      // Reload customer detail after update
      final customerData = await loadCustomerDetail(organizationId, workspaceId);
      
      // Reload journey list after updating customer profile
      _ref.invalidate(customerJourneyProvider(_customerId));
      await _ref
          .read(customerJourneyProvider(_customerId).notifier)
          .loadJourneyList(organizationId, workspaceId);
          
      return customerData;
    } catch (error) {
      // Debug
      print('Error in updateCustomer: $error');
      
      // Trường hợp lỗi từ Dio
      if (error is DioException) {
        print('DioException status code: ${error.response?.statusCode}');
        print('DioException response data: ${error.response?.data}');
        
        final responseData = error.response?.data;
        if (responseData is Map<String, dynamic> && responseData['message'] != null) {
          throw responseData['message'] as String;
        }
      }
      
      // Nếu là String (đã xử lý ở trên) thì throw trực tiếp
      if (error is String) {
        rethrow;
      }
      
      // Trường hợp lỗi khác
      throw 'Lỗi khi cập nhật khách hàng';
    }
  }

  Future<Map<String, dynamic>?> deleteCustomer(
    String organizationId,
    String workspaceId,
  ) async {
    try {
      final response = await _customerRepository.deleteCustomer(
        organizationId,
        workspaceId,
        _customerId,
      );
      
      // Kiểm tra mã trạng thái từ API
      if (!Helpers.isResponseSuccess(response)) {
        final errorMessage = response['message'] as String? ?? 'Đã xảy ra lỗi khi xóa khách hàng';
        throw errorMessage;
      }
      
      state = const AsyncValue.data(null);
      return null;
    } catch (error) {
      // Debug
      print('Error in deleteCustomer: $error');
      
      // Trường hợp lỗi từ Dio
      if (error is DioException) {
        print('DioException status code: ${error.response?.statusCode}');
        print('DioException response data: ${error.response?.data}');
        
        final responseData = error.response?.data;
        if (responseData is Map<String, dynamic> && responseData['message'] != null) {
          throw responseData['message'] as String;
        }
      }
      
      // Nếu là String (đã xử lý ở trên) thì throw trực tiếp
      if (error is String) {
        rethrow;
      }
      
      // Trường hợp lỗi khác
      throw 'Lỗi khi xóa khách hàng';
    }
  }

  void clearCustomerDetail() {
    state = const AsyncValue.data(null);
  }
}

class CustomerJourneyNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final CustomerRepository _customerRepository;
  final String _customerId;
  String? _lastOrganizationId;
  String? _lastWorkspaceId;
  bool _isLoading = false;

  CustomerJourneyNotifier({
    required CustomerRepository customerRepository,
    required String customerId,
  })  : _customerRepository = customerRepository,
        _customerId = customerId,
        super(const AsyncValue.loading());

  Future<void> loadJourneyList(
    String organizationId,
    String workspaceId,
  ) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    try {
      final response = await _customerRepository.getJourneyList(
        organizationId,
        workspaceId,
        _customerId,
      );
      _lastOrganizationId = organizationId;
      _lastWorkspaceId = workspaceId;
      state = AsyncValue.data(response['content'] as List);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> updateJourney(
    String organizationId,
    String workspaceId,
    String stageId,
    String note,
  ) async {
    try {
      print('CustomerJourneyNotifier.updateJourney called with stageId: $stageId, note: $note');
      
      // Nếu không có stageId, gọi createNote thay vì updateJourney
      if (stageId.isEmpty) {
        print('Calling createNote because stageId is empty');
        await _customerRepository.createNote(
          organizationId,
          workspaceId,
          _customerId,
          note,
        );
      } else {
        print('Calling updateJourney with stageId: $stageId');
        await _customerRepository.updateJourney(
          organizationId,
          workspaceId,
          _customerId,
          stageId,
          note,
        );
      }
      
      print('API call successful, reloading journey list');
      state = await AsyncValue.guard(() async {
        final response = await _customerRepository.getJourneyList(
          organizationId,
          workspaceId,
          _customerId,
        );
        _lastOrganizationId = organizationId;
        _lastWorkspaceId = workspaceId;
        print('Journey list reloaded successfully');
        return response['content'] as List;
      });
    } catch (error, stackTrace) {
      print('Error in updateJourney: $error');
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

// Customer assignments refresh notifier
final customerAssignmentRefreshProvider = StateNotifierProvider<CustomerAssignmentRefreshNotifier, int>(
  (ref) => CustomerAssignmentRefreshNotifier(),
);

class CustomerAssignmentRefreshNotifier extends StateNotifier<int> {
  CustomerAssignmentRefreshNotifier() : super(0);
  
  void notifyAssignmentChanged() {
    state = state + 1; // Increment để trigger listeners
  }
}

// Customer list refresh notifier - để refresh danh sách khi có thêm/xóa/sửa customer
final customerListRefreshProvider = StateNotifierProvider<CustomerListRefreshNotifier, int>(
  (ref) => CustomerListRefreshNotifier(),
);

class CustomerListRefreshNotifier extends StateNotifier<int> {
  CustomerListRefreshNotifier() : super(0);
  
  void notifyCustomerListChanged() {
    state = state + 1; // Increment để trigger listeners
  }
}
