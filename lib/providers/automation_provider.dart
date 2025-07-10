import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/automation/automation_config.dart';
import '../services/automation/eviction_rule_service.dart';
import '../services/automation/reminder_config_service.dart';

// Automation state notifier
class AutomationNotifier extends StateNotifier<AutomationState> {
  AutomationNotifier() : super(const AutomationState());

  // Test method để debug API calls
  Future<void> testApis(String organizationId) async {
    print('🧪 Testing APIs directly...');
    
    try {
      // Test reminder API
      print('📞 Testing Reminder API...');
      final reminderResult = await ReminderConfigService.getReminderConfigListByOrgId(organizationId);
      print('📨 Reminder result: success=${reminderResult.success}');
      print('📨 Reminder error: ${reminderResult.error}');
      if (reminderResult.data != null) {
        print('📨 Reminder data count: ${reminderResult.data!.length}');
        if (reminderResult.data!.isNotEmpty) {
          final firstReminder = reminderResult.data!.first;
          print('📨 First reminder: id=${firstReminder.id}, name=${firstReminder.name}');
        }
      }
      
      // Test eviction API
      print('📞 Testing Eviction API...');
      final evictionResult = await EvictionRuleService.getEvictionRuleList(organizationId);
      print('📨 Eviction result: success=${evictionResult.success}');
      print('📨 Eviction error: ${evictionResult.error}');
      if (evictionResult.data != null) {
        print('📨 Eviction data count: ${evictionResult.data!.length}');
        if (evictionResult.data!.isNotEmpty) {
          final firstEviction = evictionResult.data!.first;
          print('📨 First eviction: id=${firstEviction.id}, name=${firstEviction.name}');
        }
      }
      
    } catch (e) {
      print('💥 Test error: $e');
    }
  }

  // Fetch tất cả configs
  Future<void> fetchAllConfigs(String organizationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Fetch reminder configs
      final reminderResult = await ReminderConfigService.getReminderConfigListByOrgId(organizationId);
      List<AutomationConfig> reminderConfigs = [];
      
      if (reminderResult.success && reminderResult.data != null) {
        reminderConfigs = reminderResult.data!
            .map((config) => AutomationConfig.fromReminderConfig(config))
            .toList();
      }

      // Fetch eviction rules
      final evictionResult = await EvictionRuleService.getEvictionRuleList(organizationId);
      List<AutomationConfig> evictionConfigs = [];
      
      if (evictionResult.success && evictionResult.data != null) {
        evictionConfigs = evictionResult.data!
            .map((rule) => AutomationConfig.fromEvictionRule(rule))
            .toList();
      }

      // Combine và sort
      final allConfigs = [...reminderConfigs, ...evictionConfigs];
      allConfigs.sort((a, b) => b.formattedCreatedAt.compareTo(a.formattedCreatedAt));

      state = state.copyWith(
        configs: allConfigs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi khi tải danh sách automation: $e',
      );
    }
  }

  // Toggle status
  Future<void> toggleConfigStatus(String configId, String organizationId) async {
    final config = state.configs.firstWhere((c) => c.id == configId);
    
    // Cập nhật UI ngay lập tức
    final newIsUpdating = Map<String, bool>.from(state.isUpdating);
    newIsUpdating[configId] = true;
    state = state.copyWith(isUpdating: newIsUpdating);

    try {
      bool success = false;
      
      if (config.configType == 'reminder') {
        final result = await ReminderConfigService.toggleReminderConfigStatus(organizationId, configId);
        success = result.success;
      } else {
        final result = await EvictionRuleService.updateEvictionRuleStatus(
          organizationId, 
          configId, 
          !config.isActive
        );
        success = result.success;
      }

      if (success) {
        // Cập nhật state local
        final updatedConfigs = state.configs.map((c) {
          if (c.id == configId) {
            return c.copyWith(isActive: !c.isActive);
          }
          return c;
        }).toList();

        final updatedIsUpdating = Map<String, bool>.from(state.isUpdating);
        updatedIsUpdating.remove(configId);

        state = state.copyWith(
          configs: updatedConfigs,
          isUpdating: updatedIsUpdating,
        );
      } else {
        throw Exception('Không thể cập nhật trạng thái');
      }
    } catch (e) {
      final updatedIsUpdating = Map<String, bool>.from(state.isUpdating);
      updatedIsUpdating.remove(configId);
      
      state = state.copyWith(
        isUpdating: updatedIsUpdating,
        error: 'Lỗi khi cập nhật trạng thái: $e',
      );
    }
  }

  // Delete config
  Future<void> deleteConfig(String configId, String organizationId) async {
    final config = state.configs.firstWhere((c) => c.id == configId);

    try {
      bool success = false;
      
      if (config.configType == 'reminder') {
        final result = await ReminderConfigService.deleteReminderConfig(organizationId, configId);
        success = result.success;
      } else {
        final result = await EvictionRuleService.deleteEvictionRule(organizationId, configId);
        success = result.success;
      }

      if (success) {
        // Remove từ state
        final updatedConfigs = state.configs.where((c) => c.id != configId).toList();
        state = state.copyWith(configs: updatedConfigs);
      } else {
        throw Exception('Không thể xóa cấu hình');
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Lỗi khi xóa cấu hình: $e',
      );
    }
  }

  // Add new config after creation
  void addConfig(AutomationConfig config) {
    final updatedConfigs = [config, ...state.configs];
    updatedConfigs.sort((a, b) => b.formattedCreatedAt.compareTo(a.formattedCreatedAt));
    state = state.copyWith(configs: updatedConfigs);
  }

  // Refresh configs
  Future<void> refreshConfigs(String organizationId) async {
    state = state.copyWith(refreshTrigger: state.refreshTrigger + 1);
    await fetchAllConfigs(organizationId);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Dialog state notifier
class DialogNotifier extends StateNotifier<DialogState> {
  DialogNotifier() : super(const DialogState());

  void openReminderDialog([AutomationConfig? config]) {
    state = state.copyWith(
      reminderConfigOpen: true,
      selectedConfig: config,
    );
  }

  void openRecallDialog([AutomationConfig? config]) {
    state = state.copyWith(
      recallConfigOpen: true,
      selectedConfig: config,
    );
  }

  void closeReminderDialog() {
    state = state.copyWith(
      reminderConfigOpen: false,
      selectedConfig: null,
    );
  }

  void closeRecallDialog() {
    state = state.copyWith(
      recallConfigOpen: false,
      selectedConfig: null,
    );
  }

  void openDeleteAlert(AutomationConfig config) {
    state = state.copyWith(
      alertOpen: true,
      configToDelete: config,
    );
  }

  void closeDeleteAlert() {
    state = state.copyWith(
      alertOpen: false,
      configToDelete: null,
    );
  }

  void openToggleAlert(AutomationConfig config) {
    state = state.copyWith(
      toggleAlertOpen: true,
      configToToggle: config,
    );
  }

  void closeToggleAlert() {
    state = state.copyWith(
      toggleAlertOpen: false,
      configToToggle: null,
    );
  }
}

// Format helper provider
class FormatHelper {
  // Chuyển đổi thời gian (phút) sang giờ:phút
  String formatDuration(int? minutes) {
    if (minutes == null || minutes == 0) return "0 phút";
    
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0 && mins > 0) {
      return "$hours giờ $mins phút";
    } else if (hours > 0) {
      return "$hours giờ";
    } else {
      return "$mins phút";
    }
  }

  // Truncate text
  String truncateText(String? text, {int maxLength = 25}) {
    if (text == null || text.isEmpty) return "";
    if (text.length <= maxLength) return text;
    return "${text.substring(0, maxLength)}...";
  }

  // Format datetime
  String formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  // Get config type display text
  String getConfigTypeDisplay(String configType) {
    switch (configType) {
      case 'reminder':
        return 'Nhắc hẹn';
      case 'recall':
        return 'Thu hồi lead';
      default:
        return 'Không xác định';
    }
  }
}

// Providers
final automationProvider = StateNotifierProvider<AutomationNotifier, AutomationState>((ref) {
  return AutomationNotifier();
});

final dialogProvider = StateNotifierProvider<DialogNotifier, DialogState>((ref) {
  return DialogNotifier();
});

final formatHelperProvider = Provider((ref) => FormatHelper()); 