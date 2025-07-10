import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stage.dart';
import '../services/stage_api_service.dart';

// State class để quản lý stage data
class StageState {
  final bool loading;
  final String error;
  final List<Stage> stages;
  final List<StageGroupWithStages> stageGroups;
  final List<String> hiddenStages;
  final List<String> hiddenGroups;

  const StageState({
    this.loading = false,
    this.error = '',
    this.stages = const [],
    this.stageGroups = const [],
    this.hiddenStages = const [],
    this.hiddenGroups = const [],
  });

  StageState copyWith({
    bool? loading,
    String? error,
    List<Stage>? stages,
    List<StageGroupWithStages>? stageGroups,
    List<String>? hiddenStages,
    List<String>? hiddenGroups,
  }) {
    return StageState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      stages: stages ?? this.stages,
      stageGroups: stageGroups ?? this.stageGroups,
      hiddenStages: hiddenStages ?? this.hiddenStages,
      hiddenGroups: hiddenGroups ?? this.hiddenGroups,
    );
  }
}

// StateNotifier để quản lý stage logic
class StageNotifier extends StateNotifier<StageState> {
  final StageApiService _apiService;

  StageNotifier(this._apiService) : super(const StageState());

  Future<void> fetchStages(String orgId, String workspaceId) async {
    try {
      state = state.copyWith(loading: true, error: '');

      final response = await _apiService.getStageList(orgId, workspaceId);
      
      if (response.isSuccess) {
        final stageList = response.data as List;
        
        // Nhóm stages theo stageGroup
        final Map<String, StageGroupWithStages> groupedStages = {};
        final List<Stage> stages = [];
        
        for (var stageJson in stageList) {
          final stage = Stage.fromJson(stageJson);
          stages.add(stage);
          
          final groupId = stage.stageGroup.id;
          
          if (!groupedStages.containsKey(groupId)) {
            groupedStages[groupId] = StageGroupWithStages(
              group: stage.stageGroup,
              stages: [],
            );
          }
          groupedStages[groupId] = groupedStages[groupId]!.copyWith(
            stages: [...groupedStages[groupId]!.stages, stage],
          );
        }
        
        state = state.copyWith(
          stages: stages,
          stageGroups: groupedStages.values.toList(),
        );
        
        // Tải cấu hình ẩn/hiện
        await fetchHiddenStages(orgId, workspaceId);
      } else {
        state = state.copyWith(error: response.message);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> fetchHiddenStages(String orgId, String workspaceId) async {
    try {
      final response = await _apiService.getHiddenStagesAndGroups(orgId, workspaceId);
      
      state = state.copyWith(
        hiddenStages: response.hiddenStages ?? [],
        hiddenGroups: response.hiddenGroups ?? [],
      );
    } catch (e) {
      print("Error fetching hidden stages: $e");
    }
  }
  
  bool isStageHidden(String stageId) => state.hiddenStages.contains(stageId);
  bool isGroupHidden(String groupId) => state.hiddenGroups.contains(groupId);
}

// API Service Provider
final stageApiServiceProvider = Provider<StageApiService>((ref) {
  return StageApiService();
});

// Stage Provider
final stageProvider = StateNotifierProvider<StageNotifier, StageState>((ref) {
  final apiService = ref.watch(stageApiServiceProvider);
  return StageNotifier(apiService);
}); 