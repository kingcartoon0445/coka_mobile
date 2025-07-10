import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../models/automation/automation_config.dart';

import 'base_automation_dialog.dart';
import 'selectors/workspace_selector.dart';
import 'selectors/multi_select_popover.dart';
import 'selectors/time_selector.dart';

/// Enhanced RecallConfigDialog với tabs và các tính năng đặc biệt
class RecallConfigDialog extends ConsumerStatefulWidget {
  final String organizationId;
  final AutomationConfig? editingConfig;

  const RecallConfigDialog({
    super.key,
    required this.organizationId,
    this.editingConfig,
  });

  @override
  ConsumerState<RecallConfigDialog> createState() => _RecallConfigDialogState();
}

class _RecallConfigDialogState extends ConsumerState<RecallConfigDialog> 
    with TickerProviderStateMixin {
  TabController? _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _messageController = TextEditingController();
  
  // State variables
  WorkspaceItem? _selectedWorkspace;
  TimeConfig _timeConfig = const TimeConfig(hours: 24, minutes: 0);
  bool _enableNotificationBeforeRecall = false;
  int _notificationHoursBefore = 1;
  int _maxAttempts = 3;
  
  // Stage recall configuration
  bool _updateStageOnRecall = false;
  List<String> _selectedRecallStages = [];
  
  // Rule configuration
  RecallRule _selectedRule = RecallRule.team;
  String? _selectedTeamId;
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Only initialize TabController if editing (need history tab)
    if (widget.editingConfig != null) {
      _tabController = TabController(length: 2, vsync: this);
    }
    _initializeFromConfig();
    _loadInitialData();
  }

  void _initializeFromConfig() {
    if (widget.editingConfig != null) {
      final config = widget.editingConfig!;
      _messageController.text = config.notificationMessage ?? '';
      _timeConfig = TimeConfig.fromMinutes(config.duration ?? 1440);
      // TODO: Load other fields from config
    }
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workspaceSelectorProvider.notifier).loadWorkspaces(widget.organizationId);
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showHistoryTab = widget.editingConfig != null;
    print('🔍 RecallConfigDialog.build - editingConfig: ${widget.editingConfig?.id}, showHistoryTab: $showHistoryTab');
    
    return BaseAutomationDialog(
      title: widget.editingConfig == null 
          ? 'Tạo quy tắc thu hồi'
          : 'Chỉnh sửa quy tắc thu hồi',
      maxHeight: MediaQuery.of(context).size.height * 0.9,
      isScrollable: showHistoryTab ? false : true, // Only disable scrolling if using tabs
      content: showHistoryTab 
          ? SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  // Tab bar (only when editing)
                  TabBar(
                    controller: _tabController!,
                    labelColor: const Color(0xFF3B82F6),
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: const Color(0xFF3B82F6),
                    tabs: const [
                      Tab(text: 'Cấu hình'),
                      Tab(text: 'Lịch sử'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController!,
                      children: [
                        _buildConfigTab(),
                        _buildHistoryTab(),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : _buildConfigForm(), // Direct form when creating
      
      actions: [
        AutomationDialogButton(
          text: 'Hủy',
          onPressed: () => Navigator.pop(context),
        ),
        AutomationDialogButton(
          text: widget.editingConfig == null ? 'Tạo' : 'Cập nhật',
          isPrimary: true,
          isLoading: _isSubmitting,
          onPressed: _canSubmit() ? _handleSubmit : null,
        ),
      ],
    );
  }

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: _buildConfigForm(),
    );
  }

  Widget _buildConfigForm() {
    final workspaceState = ref.watch(workspaceSelectorProvider);
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildConfigurationSection(workspaceState),
          const SizedBox(height: 24),
          _buildStageRecallSection(),
          const SizedBox(height: 24),
          _buildRuleConfigSection(),
          const SizedBox(height: 24),
          _buildNotificationSection(),
          const SizedBox(height: 24),
          _buildAdvancedSettings(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return EvictionLogHistory(
      organizationId: widget.organizationId,
      configId: widget.editingConfig?.id,
    );
  }



  Widget _buildConfigurationSection(WorkspaceState workspaceState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Điều kiện áp dụng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        _buildInteractiveText(workspaceState),
      ],
    );
  }

  Widget _buildInteractiveText(WorkspaceState workspaceState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workspace selection
          _buildConfigRow(
            label: 'Không gian làm việc',
            child: WorkspaceSelector(
              workspaces: workspaceState.workspaces,
              selectedWorkspace: _selectedWorkspace,
              onWorkspaceSelected: (workspace) {
                setState(() {
                  _selectedWorkspace = workspace;
                });
              },
              isLoading: workspaceState.isLoading,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Time selection
          _buildConfigRow(
            label: 'Thời gian thu hồi',
            child: TimeSelector(
              timeConfig: _timeConfig,
              onTimeChanged: (newTimeConfig) {
                setState(() {
                  _timeConfig = newTimeConfig;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildStageRecallSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cập nhật trạng thái khi thu hồi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        
        StageRecallPopover(
          updateStageOnRecall: _updateStageOnRecall,
          selectedStages: _selectedRecallStages,
          availableStages: _getMockStages(),
          onUpdateStageChanged: (value) {
            setState(() {
              _updateStageOnRecall = value;
            });
          },
          onStageSelectionChanged: (selectedIds) {
            setState(() {
              _selectedRecallStages = selectedIds;
            });
          },
        ),
      ],
    );
  }

  Widget _buildRuleConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chuyển khách hàng đến',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        
        RuleConfigPopover(
          selectedRule: _selectedRule,
          selectedTeamId: _selectedTeamId,
          availableTeams: _getMockTeams(),
          onRuleChanged: (rule) {
            setState(() {
              _selectedRule = rule;
              if (rule != RecallRule.assignTo) {
                _selectedTeamId = null;
              }
            });
          },
          onTeamChanged: (teamId) {
            setState(() {
              _selectedTeamId = teamId;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông báo trước khi thu hồi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _enableNotificationBeforeRecall,
          onChanged: (value) {
            setState(() {
              _enableNotificationBeforeRecall = value ?? false;
            });
          },
          title: const Text('Gửi thông báo trước khi thu hồi'),
          subtitle: _enableNotificationBeforeRecall 
              ? Text('Thông báo trước $_notificationHoursBefore giờ')
              : const Text('Không thông báo trước'),
        ),
        
        if (_enableNotificationBeforeRecall)
          Container(
            margin: const EdgeInsets.only(left: 16, top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Thông báo trước '),
                    SizedBox(
                      width: 80,
                      child: DropdownButtonFormField<int>(
                        value: _notificationHoursBefore,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 giờ')),
                          DropdownMenuItem(value: 2, child: Text('2 giờ')),
                          DropdownMenuItem(value: 4, child: Text('4 giờ')),
                          DropdownMenuItem(value: 8, child: Text('8 giờ')),
                          DropdownMenuItem(value: 24, child: Text('1 ngày')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _notificationHoursBefore = value ?? 1;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Nội dung thông báo trước khi thu hồi...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cài đặt nâng cao',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            const Text('Số lần thu hồi tối đa: '),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: _maxAttempts.toString(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _maxAttempts = int.tryParse(value) ?? 3;
                  });
                },
              ),
            ),
            const Text(' lần'),
          ],
        ),
      ],
    );
  }

  bool _canSubmit() {
    return !_isSubmitting && 
           _selectedWorkspace != null;
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 2)); // Mock delay
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editingConfig == null 
                ? 'Đã tạo quy tắc thu hồi thành công' 
                : 'Đã cập nhật quy tắc thu hồi thành công'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Mock data methods
  List<SelectableItem> _getMockStages() {
    return [
      const SelectableItem(id: '1', label: 'Mới tiếp nhận', color: Colors.blue),
      const SelectableItem(id: '2', label: 'Đang tư vấn', color: Colors.orange),
      const SelectableItem(id: '3', label: 'Quan tâm', color: Colors.green),
      const SelectableItem(id: '4', label: 'Chờ quyết định', color: Colors.purple),
    ];
  }

  List<TeamItem> _getMockTeams() {
    return [
      const TeamItem(id: '1', name: 'Đội Sales A'),
      const TeamItem(id: '2', name: 'Đội Sales B'),
      const TeamItem(id: '3', name: 'Đội Marketing'),
    ];
  }
}

/// Recall-specific enums and models
enum RecallRule {
  team,      // Đội sale của người phụ trách
  workspace, // Không gian làm việc
  assignTo,  // Chỉ định đội cụ thể
}

class TeamItem {
  final String id;
  final String name;

  const TeamItem({
    required this.id,
    required this.name,
  });
}

/// Widget riêng cho Stage Recall configuration
class StageRecallPopover extends StatelessWidget {
  final bool updateStageOnRecall;
  final List<String> selectedStages;
  final List<SelectableItem> availableStages;
  final Function(bool) onUpdateStageChanged;
  final Function(List<String>) onStageSelectionChanged;

  const StageRecallPopover({
    super.key,
    required this.updateStageOnRecall,
    required this.selectedStages,
    required this.availableStages,
    required this.onUpdateStageChanged,
    required this.onStageSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioListTile<bool>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Không cập nhật trạng thái chăm sóc'),
            value: false,
            groupValue: updateStageOnRecall,
            onChanged: (value) => onUpdateStageChanged(value!),
          ),
          RadioListTile<bool>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Chuyển trạng thái chăm sóc sang:'),
            value: true,
            groupValue: updateStageOnRecall,
            onChanged: (value) => onUpdateStageChanged(value!),
          ),
          if (updateStageOnRecall) ...[
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(left: 16),
              child: StageSelector(
                stages: availableStages,
                selectedStageIds: selectedStages,
                onSelectionChanged: onStageSelectionChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget riêng cho Rule configuration
class RuleConfigPopover extends StatelessWidget {
  final RecallRule selectedRule;
  final String? selectedTeamId;
  final List<TeamItem> availableTeams;
  final Function(RecallRule) onRuleChanged;
  final Function(String?) onTeamChanged;

  const RuleConfigPopover({
    super.key,
    required this.selectedRule,
    this.selectedTeamId,
    required this.availableTeams,
    required this.onRuleChanged,
    required this.onTeamChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioListTile<RecallRule>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Đội sale của người phụ trách'),
            value: RecallRule.team,
            groupValue: selectedRule,
            onChanged: (value) => onRuleChanged(value!),
          ),
          RadioListTile<RecallRule>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Không gian làm việc'),
            value: RecallRule.workspace,
            groupValue: selectedRule,
            onChanged: (value) => onRuleChanged(value!),
          ),
          RadioListTile<RecallRule>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Chỉ định đội cụ thể'),
            value: RecallRule.assignTo,
            groupValue: selectedRule,
            onChanged: (value) => onRuleChanged(value!),
          ),
          if (selectedRule == RecallRule.assignTo) ...[
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(left: 16),
              child: DropdownButtonFormField<String>(
                value: selectedTeamId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Chọn đội',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: availableTeams.map((team) {
                  return DropdownMenuItem<String>(
                    value: team.id,
                    child: Text(team.name),
                  );
                }).toList(),
                onChanged: onTeamChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget cho History tab
class EvictionLogHistory extends ConsumerWidget {
  final String organizationId;
  final String? configId;

  const EvictionLogHistory({
    super.key,
    required this.organizationId,
    this.configId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implement actual history loading
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Lịch sử thực thi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tính năng đang được phát triển',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
} 