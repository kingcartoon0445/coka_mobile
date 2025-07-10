import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/repositories/report_repository.dart';
import '../api/api_client.dart';
import '../pages/organization/detail_organization/workspace/reports/components/report_providers.dart';

// Provider để kiểm soát việc load dữ liệu - đã được thay thế bởi reportsPageShouldLoadProvider
// final shouldLoadReportsProvider = StateProvider<bool>((ref) => false);

// Cache key để quản lý việc invalidate cache
final _cacheKeyProvider = StateProvider<int>((ref) => 0);

// Provider để lưu trữ params hiện tại
final reportParamsProvider = StateProvider<ReportParams?>((ref) => null);

class ReportParams {
  final String organizationId;
  final String workspaceId;
  final String startDate;
  final String endDate;

  ReportParams({
    required this.organizationId,
    required this.workspaceId,
    required this.startDate,
    required this.endDate,
  });

  Map<String, String> toQueryParameters() {
    return {
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}

class ReportOverTimeParams extends ReportParams {
  final String type;

  ReportOverTimeParams({
    required super.organizationId,
    required super.workspaceId,
    required super.startDate,
    required super.endDate,
    required this.type,
  });

  @override
  Map<String, String> toQueryParameters() {
    return {
      ...super.toQueryParameters(),
      'Type': type,
    };
  }
}

final reportSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, ReportParams>(
  (ref, params) async {
    final shouldLoad = ref.read(reportsPageShouldLoadProvider);
    if (!shouldLoad) {
      return {'content': [], 'metadata': {}};
    }

    try {
      print('reportSummaryProvider - Starting API call');
      final repository = ReportRepository(ApiClient());
      final response = await repository.getSummaryData(
        params.organizationId,
        params.workspaceId,
        params.startDate,
        params.endDate,
      );
      return response;
    } catch (e, stack) {
      print('reportSummaryProvider - API error: $e');
      print('reportSummaryProvider - Stack trace: $stack');
      rethrow;
    }
  },
);

final reportStatisticsByUtmSourceProvider =
    FutureProvider.family<Map<String, dynamic>, ReportParams>(
  (ref, params) async {
    final shouldLoad = ref.read(reportsPageShouldLoadProvider);
    print('reportStatisticsByUtmSourceProvider - shouldLoad: $shouldLoad');
    if (!shouldLoad) {
      return {'content': [], 'metadata': {}};
    }

    try {
      print('reportStatisticsByUtmSourceProvider - Starting API call');
      final repository = ReportRepository(ApiClient());
      final response = await repository.getStatisticsByUtmSource(
        params.organizationId,
        params.workspaceId,
        params.startDate,
        params.endDate,
      );
      print('reportStatisticsByUtmSourceProvider - API call successful');
      return response;
    } catch (e, stack) {
      print('reportStatisticsByUtmSourceProvider - API error: $e');
      print('reportStatisticsByUtmSourceProvider - Stack trace: $stack');
      rethrow;
    }
  },
);

final reportStatisticsByDataSourceProvider =
    FutureProvider.family<Map<String, dynamic>, ReportParams>(
  (ref, params) async {
    final shouldLoad = ref.read(reportsPageShouldLoadProvider);
    if (!shouldLoad) {
      return {'content': [], 'metadata': {}};
    }

    final repository = ReportRepository(ApiClient());
    final response = await repository.getStatisticsByDataSource(
      params.organizationId,
      params.workspaceId,
      params.startDate,
      params.endDate,
    );
    return response;
  },
);

final reportStatisticsByTagProvider =
    FutureProvider.family<Map<String, dynamic>, ReportParams>(
  (ref, params) async {
    final shouldLoad = ref.read(reportsPageShouldLoadProvider);
    if (!shouldLoad) {
      return {'content': [], 'metadata': {}};
    }

    final repository = ReportRepository(ApiClient());
    final response = await repository.getStatisticsByTag(
      params.organizationId,
      params.workspaceId,
      params.startDate,
      params.endDate,
    );
    return response;
  },
);

final reportChartByOverTimeProvider =
    FutureProvider.family<Map<String, dynamic>, ReportOverTimeParams>(
  (ref, params) async {
    final shouldLoad = ref.read(reportsPageShouldLoadProvider);
    if (!shouldLoad) {
      return {'content': [], 'metadata': {}};
    }

    final repository = ReportRepository(ApiClient());
    final response = await repository.getChartByOverTime(
      params.organizationId,
      params.workspaceId,
      params.startDate,
      params.endDate,
      params.type,
    );
    return response;
  },
);

final reportChartByRatingProvider =
    FutureProvider.family<Map<String, dynamic>, ReportParams>(
  (ref, params) async {
    final shouldLoad = ref.read(reportsPageShouldLoadProvider);
    if (!shouldLoad) {
      return {'content': [], 'metadata': {}};
    }

    final repository = ReportRepository(ApiClient());
    final response = await repository.getChartByRating(
      params.organizationId,
      params.workspaceId,
      params.startDate,
      params.endDate,
    );
    return response;
  },
);

final reportStatisticsByUserProvider =
    FutureProvider.family<Map<String, dynamic>, ReportParams>(
  (ref, params) async {
    final shouldLoad = ref.read(reportsPageShouldLoadProvider);
    if (!shouldLoad) {
      return {'content': [], 'metadata': {}};
    }

    final repository = ReportRepository(ApiClient());
    final response = await repository.getStatisticsByUser(
      params.organizationId,
      params.workspaceId,
      params.startDate,
      params.endDate,
    );
    return response;
  },
);

final reportStatisticsByStageGroupProvider = StateNotifierProvider.family<
    ReportStatisticsByStageGroupNotifier,
    AsyncValue<Map<String, dynamic>>,
    ReportStageGroupParams>((ref, params) {
  return ReportStatisticsByStageGroupNotifier(
      ReportRepository(ApiClient()), params, ref);
});

class ReportStageGroupParams {
  final String organizationId;
  final String workspaceId;
  final Map<String, String>? queryParameters;

  ReportStageGroupParams({
    required this.organizationId,
    required this.workspaceId,
    this.queryParameters,
  });
}

class ReportStatisticsByStageGroupNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ReportRepository _reportRepository;
  final ReportStageGroupParams _params;
  final Ref _ref;
  bool _isLoading = false;
  Map<String, String>? _lastQueryParameters;

  ReportStatisticsByStageGroupNotifier(
    this._reportRepository,
    this._params,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    _ref.listen(reportsPageShouldLoadProvider, (previous, next) {
      if (next) {
        fetchStatisticsByStageGroup();
      }
    });
  }

  Future<void> fetchStatisticsByStageGroup() async {
    // Kiểm tra nếu đang loading hoặc tham số không thay đổi thì không gọi lại API
    if (_isLoading) return;
    
    // So sánh tham số với lần gọi trước
    if (_lastQueryParameters != null && 
        _params.queryParameters != null &&
        _mapEquals(_lastQueryParameters!, _params.queryParameters!)) {
      return;
    }
    
    try {
      _isLoading = true;
      if (state is! AsyncLoading) {
        state = const AsyncValue.loading();
      }
      
      final response = await _reportRepository.getStatisticsByStageGroup(
        _params.organizationId,
        _params.workspaceId,
        queryParameters: _params.queryParameters,
      );
      
      // Lưu lại tham số cuối cùng
      if (_params.queryParameters != null) {
        _lastQueryParameters = Map<String, String>.from(_params.queryParameters!);
      } else {
        _lastQueryParameters = null;
      }
      
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isLoading = false;
    }
  }
  
  bool _mapEquals(Map<String, String> map1, Map<String, String> map2) {
    if (map1.length != map2.length) return false;
    return map1.entries.every((e) => map2[e.key] == e.value);
  }
}

// Provider chính để lấy dữ liệu báo cáo
final reportDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final params = ref.watch(reportParamsProvider);
  final shouldLoad = ref.watch(reportsPageShouldLoadProvider);

  if (params == null || !shouldLoad) {
    return {
      'summary': {'content': [], 'metadata': {}},
      'utmSource': {'content': [], 'metadata': {}},
      'dataSource': {'content': [], 'metadata': {}},
      'tag': {'content': [], 'metadata': {}},
      'rating': {'content': [], 'metadata': {}},
      'user': {'content': [], 'metadata': {}},
    };
  }

  try {
    print('reportDataProvider - Starting API calls with params:');

    final repository = ReportRepository(ApiClient());

    // Khởi tạo kết quả mặc định
    final Map<String, dynamic> result = {
      'summary': {'content': [], 'metadata': {}},
      'utmSource': {'content': [], 'metadata': {}},
      'dataSource': {'content': [], 'metadata': {}},
      'tag': {'content': [], 'metadata': {}},
      'rating': {'content': [], 'metadata': {}},
      'user': {'content': [], 'metadata': {}},
    };

    // Gọi từng API riêng biệt và xử lý lỗi riêng
    try {
      result['summary'] = await repository.getSummaryData(
        params.organizationId,
        params.workspaceId,
        params.startDate,
        params.endDate,
      );
    } catch (e) {
      print('Error fetching summary data: $e');
      // Giữ giá trị mặc định nếu có lỗi
    }

    try {
      result['utmSource'] = await repository.getStatisticsByUtmSource(
        params.organizationId,
        params.workspaceId,
        params.startDate,
        params.endDate,
      );
    } catch (e) {
      print('Error fetching utm source data: $e');
      // Giữ giá trị mặc định nếu có lỗi
    }

    try {
      result['dataSource'] = await repository.getStatisticsByDataSource(
        params.organizationId,
        params.workspaceId,
        params.startDate,
        params.endDate,
      );
    } catch (e) {
      print('Error fetching data source data: $e');
      // Giữ giá trị mặc định nếu có lỗi
    }

    try {
      result['tag'] = await repository.getStatisticsByTag(
        params.organizationId,
        params.workspaceId,
        params.startDate,
        params.endDate,
      );
    } catch (e) {
      print('Error fetching tag data: $e');
      // Giữ giá trị mặc định nếu có lỗi
    }

    try {
      result['rating'] = await repository.getChartByRating(
        params.organizationId,
        params.workspaceId,
        params.startDate,
        params.endDate,
      );
    } catch (e) {
      print('Error fetching rating data: $e');
      // Giữ giá trị mặc định nếu có lỗi
    }

    try {
      result['user'] = await repository.getStatisticsByUser(
        params.organizationId,
        params.workspaceId,
        params.startDate,
        params.endDate,
      );
    } catch (e) {
      print('Error fetching user data: $e');
      // Giữ giá trị mặc định nếu có lỗi
    }

    print('reportDataProvider - API calls completed');
    return result;
  } catch (e, stack) {
    print('reportDataProvider - Stack trace: $stack');
    rethrow;
  }
});
