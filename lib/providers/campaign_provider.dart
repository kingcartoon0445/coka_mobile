import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/repositories/campaign_repository.dart';
import '../api/api_client.dart';
import '../models/campaign.dart';
import '../../core/utils/helpers.dart';
final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  return CampaignRepository(ApiClient());
});

// Provider chính cho danh sách chiến dịch
final campaignsProvider = StateNotifierProvider<CampaignsNotifier, AsyncValue<List<Campaign>>>(
  (ref) => CampaignsNotifier(ref.read(campaignRepositoryProvider)),
);

// Provider cho chiến dịch được chọn để xem chi tiết
final selectedCampaignProvider = StateProvider<Campaign?>((ref) => null);

// Provider cho việc lọc chiến dịch
final campaignFilterProvider = StateProvider<String>((ref) => 'all');

// Provider cho việc tìm kiếm chiến dịch
final campaignSearchQueryProvider = StateProvider<String>((ref) => '');

// Provider cho trang hiện tại và tổng số trang phân trang
final campaignPaginationProvider = StateProvider<Map<String, dynamic>>((ref) => {
      'page': 1,
      'limit': 10,
      'total': 0,
    });

class CampaignsNotifier extends StateNotifier<AsyncValue<List<Campaign>>> {
  final CampaignRepository _campaignRepository;
  String? _lastOrganizationId;
  Map<String, String>? _lastQueryParams;

  CampaignsNotifier(this._campaignRepository) : super(const AsyncValue.loading());

  Future<void> loadCampaigns(
    String organizationId, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      // Kiểm tra nếu đã load rồi với các tham số giống nhau
      if (_lastOrganizationId == organizationId &&
          _mapEquals(_lastQueryParams, queryParameters)) {
        return;
      }

      state = const AsyncValue.loading();
      
      final response = await _campaignRepository.getCampaigns(
        organizationId,
        queryParameters: queryParameters,
      );

      if (Helpers.isResponseSuccess(response)) {
        final campaignsData = response['content'] as List<dynamic>;
        final campaigns = campaignsData
            .map((data) => Campaign.fromJson(data as Map<String, dynamic>))
            .toList();

        _lastOrganizationId = organizationId;
        _lastQueryParams = queryParameters != null 
            ? Map<String, String>.from(queryParameters)
            : null;

        state = AsyncValue.data(campaigns);
      } else {
        state = AsyncValue.error(
          response['message'] ?? 'Unknown error',
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadCampaignsPaging(
    String organizationId, {
    int? page,
    int? size,
    String? search,
    Map<String, String>? additionalParams,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _campaignRepository.getCampaignsPaging(
        organizationId,
        page: page,
        size: size,
        search: search,
        additionalParams: additionalParams,
      );

      if (Helpers.isResponseSuccess(response)) {
        final campaignsData = response['content'] as List<dynamic>;
        final campaigns = campaignsData
            .map((data) => Campaign.fromJson(data as Map<String, dynamic>))
            .toList();

        state = AsyncValue.data(campaigns);
      } else {
        state = AsyncValue.error(
          response['message'] ?? 'Unknown error',
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Campaign?> createCampaign(
    String organizationId,
    Map<String, dynamic> campaignData,
  ) async {
    try {
      final response = await _campaignRepository.createCampaign(
        organizationId,
        campaignData,
      );

      if (Helpers.isResponseSuccess(response)) {
        final newCampaign = Campaign.fromJson(response['content']);
        
        // Cập nhật danh sách chiến dịch
        state.whenData((campaigns) {
          state = AsyncValue.data([newCampaign, ...campaigns]);
        });
        
        return newCampaign;
      }
      return null;
    } catch (error) {
      return null;
    }
  }

  Future<bool> updateCampaign(
    String organizationId,
    String campaignId,
    Map<String, dynamic> campaignData,
  ) async {
    try {
      final response = await _campaignRepository.updateCampaign(
        organizationId,
        campaignId,
        campaignData,
      );

      if (Helpers.isResponseSuccess(response)) {
        final updatedCampaign = Campaign.fromJson(response['content']);
        
        // Cập nhật danh sách chiến dịch
        state.whenData((campaigns) {
          final updatedCampaigns = campaigns.map((campaign) {
            return campaign.id == campaignId ? updatedCampaign : campaign;
          }).toList();
          state = AsyncValue.data(updatedCampaigns);
        });
        
        return true;
      }
      return false;
    } catch (error) {
      return false;
    }
  }

  Future<bool> deleteCampaign(
    String organizationId,
    String campaignId,
  ) async {
    try {
      final response = await _campaignRepository.deleteCampaign(
        organizationId,
        campaignId,
      );

      if (Helpers.isResponseSuccess(response)) {
        // Xóa chiến dịch khỏi danh sách
        state.whenData((campaigns) {
          final updatedCampaigns = campaigns.where((campaign) => campaign.id != campaignId).toList();
          state = AsyncValue.data(updatedCampaigns);
        });
        
        return true;
      }
      return false;
    } catch (error) {
      return false;
    }
  }

  bool _mapEquals(Map<String, String>? map1, Map<String, String>? map2) {
    if (map1 == null || map2 == null) return map1 == map2;
    if (map1.length != map2.length) return false;
    return map1.entries.every((e) => map2[e.key] == e.value);
  }
} 