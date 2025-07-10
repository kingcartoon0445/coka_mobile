import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/automation/automation_config.dart';
import '../../../../providers/automation_provider.dart';
import 'components/index.dart';

class AutomationPage extends ConsumerStatefulWidget {
  final String organizationId;
  
  const AutomationPage({
    super.key,
    required this.organizationId,
  });
  
  @override
  ConsumerState<AutomationPage> createState() => _AutomationPageState();
}

class _AutomationPageState extends ConsumerState<AutomationPage> {
  @override
  void initState() {
    super.initState();
    // Load automation configs using Riverpod
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(automationProvider.notifier).fetchAllConfigs(widget.organizationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch automation state
    final automationState = ref.watch(automationProvider);

    // Listen for errors and show snackbar
    ref.listen<AutomationState>(automationProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        ref.read(automationProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Automation',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(automationProvider.notifier).refreshConfigs(widget.organizationId),
        child: _buildBody(automationState),
      ),
    );
  }

  Widget _buildBody(AutomationState automationState) {
    // Show loading skeleton when loading and no data
    if (automationState.isLoading && automationState.configs.isEmpty) {
      return AutomationGrid(
        organizationId: widget.organizationId,
        configs: [], // Empty list to trigger skeleton
        isLoading: true,
        onNavigateToDetail: (_) {}, // Disable navigation to detail
        onToggleConfig: _toggleConfig,
        onDeleteConfig: _deleteConfig,
      );
    }
    
    // Show empty state when not loading and no data
    if (automationState.configs.isEmpty) {
      return const AutomationEmptyState();
    }

    // Show actual data
    return AutomationGrid(
      organizationId: widget.organizationId,
      configs: automationState.configs,
      isLoading: automationState.isLoading,
      onNavigateToDetail: (_) {}, // Disable navigation to detail
      onToggleConfig: _toggleConfig,
      onDeleteConfig: _deleteConfig,
    );
  }

  void _toggleConfig(String configId, bool isActive) async {
    ref.read(automationProvider.notifier).toggleConfigStatus(configId, widget.organizationId);
  }

  void _deleteConfig(AutomationConfig config) {
    showDialog(
      context: context,
      builder: (context) => AutomationDeleteDialog(
        config: config,
        onConfirm: () => ref.read(automationProvider.notifier).deleteConfig(config.id, widget.organizationId),
      ),
    );
  }
} 