import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../shared/widgets/dropdown_button_widget.dart';

/// Model cho workspace item
class WorkspaceItem {
  final String id;
  final String name;
  final bool isSelected;

  const WorkspaceItem({
    required this.id,
    required this.name,
    this.isSelected = false,
  });

  WorkspaceItem copyWith({
    String? id,
    String? name,
    bool? isSelected,
  }) {
    return WorkspaceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Selector cho workspace với interactive text styling
class WorkspaceSelector extends ConsumerWidget {
  final List<WorkspaceItem> workspaces;
  final WorkspaceItem? selectedWorkspace;
  final Function(WorkspaceItem) onWorkspaceSelected;
  final bool isLoading;

  const WorkspaceSelector({
    super.key,
    required this.workspaces,
    this.selectedWorkspace,
    required this.onWorkspaceSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<WorkspaceItem>(
      onSelected: onWorkspaceSelected,
      enabled: !isLoading && workspaces.isNotEmpty,
      itemBuilder: (context) => workspaces.map((workspace) {
        return PopupMenuItem<WorkspaceItem>(
          value: workspace,
          child: Row(
            children: [
              if (selectedWorkspace?.id == workspace.id)
                const Icon(
                  Icons.check,
                  size: 16,
                  color: Color(0xFF3B82F6),
                ),
              if (selectedWorkspace?.id != workspace.id)
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  workspace.name,
                  style: TextStyle(
                    color: selectedWorkspace?.id == workspace.id
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF1F2937),
                    fontWeight: selectedWorkspace?.id == workspace.id
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: _buildSelector(context),
    );
  }

  Widget _buildSelector(BuildContext context) {
    return PrimaryDropdownButton(
      text: selectedWorkspace?.name ?? 'Chọn không gian làm việc',
      isLoading: isLoading,
      isEnabled: !isLoading && workspaces.isNotEmpty,
    );
  }
}

/// Provider để quản lý workspace state
class WorkspaceState {
  final List<WorkspaceItem> workspaces;
  final bool isLoading;
  final String? error;

  const WorkspaceState({
    this.workspaces = const [],
    this.isLoading = false,
    this.error,
  });

  WorkspaceState copyWith({
    List<WorkspaceItem>? workspaces,
    bool? isLoading,
    String? error,
  }) {
    return WorkspaceState(
      workspaces: workspaces ?? this.workspaces,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  WorkspaceNotifier() : super(const WorkspaceState());

  Future<void> loadWorkspaces(String organizationId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // TODO: Implement actual API call
      // Temporary mock data
      await Future.delayed(const Duration(milliseconds: 500));
      
      final mockWorkspaces = [
        const WorkspaceItem(id: '1', name: 'Workspace mặc định'),
        const WorkspaceItem(id: '2', name: 'Sales Team'),
        const WorkspaceItem(id: '3', name: 'Marketing Team'),
      ];
      
      state = state.copyWith(
        workspaces: mockWorkspaces,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}

final workspaceSelectorProvider = StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
  return WorkspaceNotifier();
}); 