import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../models/automation/automation_config.dart';

import 'base_automation_dialog.dart';
import 'selectors/workspace_selector.dart';
import 'selectors/multi_select_popover.dart';
import 'selectors/time_selector.dart';

/// Enhanced ReminderConfigDialog với đầy đủ tính năng theo hướng dẫn
class ReminderConfigDialog extends ConsumerStatefulWidget {
  final String organizationId;
  final AutomationConfig? editingConfig;

  const ReminderConfigDialog({

    super.key,
    required this.organizationId,
    this.editingConfig,
  });

  @override
  ConsumerState<ReminderConfigDialog> createState() => _ReminderConfigDialogState();
}

class _ReminderConfigDialogState extends ConsumerState<ReminderConfigDialog> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  TabController? _tabController;
  
  // Form controllers
  final _messageController = TextEditingController();
  
  // State variables
  WorkspaceItem? _selectedWorkspace;
  List<String> _selectedCategories = [];
  List<String> _selectedSources = [];
  List<String> _selectedStages = [];
  TimeConfig _timeConfig = const TimeConfig(hours: 0, minutes: 30);
  bool _enableTimeFrame = false;
  bool _enableRepeat = false;
  final List<String> _selectedWeekdays = [];
  String _startTime = '09:00';
  String _endTime = '18:00';
  int _repeatTimes = 1;
  int _repeatInterval = 60; // minutes
  
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
      _timeConfig = TimeConfig.fromMinutes(config.duration ?? 30);
      // TODO: Load other fields from config
    }
  }

  void _loadInitialData() {
    // Load workspaces, categories, sources, stages
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
    print('🔍 ReminderConfigDialog.build - editingConfig: ${widget.editingConfig?.id}, showHistoryTab: $showHistoryTab');
    
    return BaseAutomationDialog(
      title: widget.editingConfig == null 
          ? 'Tạo nhắc hẹn chăm sóc'
          : 'Chỉnh sửa nhắc hẹn chăm sóc',
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
          _buildMessageSection(),
          const SizedBox(height: 24),
          _buildOptionalSettings(),
        ],
      ),
    );
  }

  Widget _buildConfigTab() {
    final workspaceState = ref.watch(workspaceSelectorProvider);
    
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigurationSection(workspaceState),
            const SizedBox(height: 24),
            _buildMessageSection(),
            const SizedBox(height: 24),
            _buildOptionalSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Lịch sử automation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tính năng hiển thị lịch sử\nsẽ được cập nhật sớm',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
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
        
        // Interactive configuration text
        _buildInteractiveText(workspaceState),
      ],
    );
  }

  Widget _buildInteractiveText(WorkspaceState workspaceState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          
          // Category selection
          _buildConfigRow(
            label: 'Phân loại khách hàng',
            child: CategorySelector(
              categories: _getMockCategories(),
              selectedCategoryIds: _selectedCategories,
              onSelectionChanged: (selectedIds) {
                setState(() {
                  _selectedCategories = selectedIds;
                });
              },
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Source selection
          _buildConfigRow(
            label: 'Nguồn khách hàng',
            child: SourceSelector(
              sources: _getMockSources(),
              selectedSourceIds: _selectedSources,
              onSelectionChanged: (selectedIds) {
                setState(() {
                  _selectedSources = selectedIds;
                });
              },
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Stage selection
          _buildConfigRow(
            label: 'Trạng thái chăm sóc',
            child: StageSelector(
              stages: _getMockStages(),
              selectedStageIds: _selectedStages,
              onSelectionChanged: (selectedIds) {
                setState(() {
                  _selectedStages = selectedIds;
                });
              },
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Time selection
          _buildConfigRow(
            label: 'Thời gian thông báo',
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

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nội dung thông báo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _messageController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Nhập nội dung thông báo nhắc nhở...',
            helperText: 'Sử dụng {Tên KH} để hiển thị tên khách hàng trong thông báo',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập nội dung thông báo';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildOptionalSettings() {
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
        
        // Time frame setting
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _enableTimeFrame,
          onChanged: (value) {
            setState(() {
              _enableTimeFrame = value ?? false;
            });
          },
          title: const Text('Khung giờ áp dụng'),
          subtitle: _enableTimeFrame 
              ? Text('Chỉ gửi thông báo từ $_startTime đến $_endTime')
              : const Text('Gửi thông báo bất kỳ lúc nào'),
        ),
        
        if (_enableTimeFrame) _buildTimeFrameSettings(),
        
        const SizedBox(height: 12),
        
        // Repeat setting
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _enableRepeat,
          onChanged: (value) {
            setState(() {
              _enableRepeat = value ?? false;
            });
          },
          title: const Text('Lặp lại nhắc hẹn'),
          subtitle: _enableRepeat 
              ? Text('Lặp lại $_repeatTimes lần, mỗi ${_repeatInterval ~/ 60} giờ')
              : const Text('Chỉ gửi một lần'),
        ),
        
        if (_enableRepeat) _buildRepeatSettings(),
      ],
    );
  }

  Widget _buildTimeFrameSettings() {
    return Container(
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
              Expanded(
                child: _buildTimePickerField('Từ', _startTime, (time) {
                  setState(() {
                    _startTime = time;
                  });
                }),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimePickerField('Đến', _endTime, (time) {
                  setState(() {
                    _endTime = time;
                  });
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Ngày trong tuần:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _buildWeekdaySelector(),
        ],
      ),
    );
  }

  Widget _buildTimePickerField(String label, String time, Function(String) onTimeChanged) {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(time.split(':')[0]),
            minute: int.parse(time.split(':')[1]),
          ),
        );
        if (picked != null) {
          final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onTimeChanged(formattedTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(time, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const Icon(Icons.access_time, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdaySelector() {
    final weekdays = [
      ('T2', 'monday'),
      ('T3', 'tuesday'),
      ('T4', 'wednesday'),
      ('T5', 'thursday'),
      ('T6', 'friday'),
      ('T7', 'saturday'),
      ('CN', 'sunday'),
    ];

    return Wrap(
      spacing: 8,
      children: weekdays.map((weekday) {
        final isSelected = _selectedWeekdays.contains(weekday.$2);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedWeekdays.remove(weekday.$2);
              } else {
                _selectedWeekdays.add(weekday.$2);
              }
            });
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
              border: Border.all(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[400]!,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                weekday.$1,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRepeatSettings() {
    return Container(
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
              const Text('Lặp lại '),
              SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: _repeatTimes.toString(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _repeatTimes = int.tryParse(value) ?? 1;
                    });
                  },
                ),
              ),
              const Text(' lần'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Khoảng cách '),
              SizedBox(
                width: 80,
                child: DropdownButtonFormField<int>(
                  value: _repeatInterval,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30 phút')),
                    DropdownMenuItem(value: 60, child: Text('1 giờ')),
                    DropdownMenuItem(value: 120, child: Text('2 giờ')),
                    DropdownMenuItem(value: 240, child: Text('4 giờ')),
                    DropdownMenuItem(value: 480, child: Text('8 giờ')),
                    DropdownMenuItem(value: 1440, child: Text('1 ngày')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _repeatInterval = value ?? 60;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    return !_isSubmitting && 
           _selectedWorkspace != null &&
           _messageController.text.trim().isNotEmpty;
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
                ? 'Đã tạo nhắc hẹn chăm sóc thành công' 
                : 'Đã cập nhật nhắc hẹn chăm sóc thành công'),
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
  List<SelectableItem> _getMockCategories() {
    return [
      const SelectableItem(id: '1', label: 'Khách hàng tiềm năng'),
      const SelectableItem(id: '2', label: 'Khách hàng quan tâm'),
      const SelectableItem(id: '3', label: 'Khách hàng VIP'),
    ];
  }

  List<SelectableItem> _getMockSources() {
    return [
      const SelectableItem(id: '1', label: 'Facebook'),
      const SelectableItem(id: '2', label: 'Website'),
      const SelectableItem(id: '3', label: 'Zalo'),
      const SelectableItem(id: '4', label: 'Giới thiệu'),
    ];
  }

  List<SelectableItem> _getMockStages() {
    return [
      const SelectableItem(id: '1', label: 'Mới tiếp nhận', color: Colors.blue),
      const SelectableItem(id: '2', label: 'Đang tư vấn', color: Colors.orange),
      const SelectableItem(id: '3', label: 'Quan tâm', color: Colors.green),
      const SelectableItem(id: '4', label: 'Chờ quyết định', color: Colors.purple),
    ];
  }
} 