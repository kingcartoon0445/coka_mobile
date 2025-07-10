import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../widgets/automation/new_automation_card.dart';
import '../../../../../widgets/automation/automation_card_skeleton.dart';
import '../../../../../models/automation/automation_config.dart';
import '../../../../../providers/automation_provider.dart';

class AutomationGrid extends ConsumerWidget {
  final String organizationId;
  final List<AutomationConfig> configs;
  final bool isLoading;
  final Function(Map<String, dynamic>) onNavigateToDetail;
  final Function(String, bool) onToggleConfig;
  final Function(AutomationConfig) onDeleteConfig;

  const AutomationGrid({
    super.key,
    required this.organizationId,
    required this.configs,
    required this.isLoading,
    required this.onNavigateToDetail,
    required this.onToggleConfig,
    required this.onDeleteConfig,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatHelper = ref.watch(formatHelperProvider);
    final automationState = ref.watch(automationProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        
        if (isLoading && configs.isEmpty) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: _getChildAspectRatio(constraints.maxWidth),
            ),
            itemCount: 6, // Show 6 skeleton cards
            itemBuilder: (context, index) => const AutomationCardSkeleton(),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: _getChildAspectRatio(constraints.maxWidth),
          ),
          itemCount: configs.length,
          itemBuilder: (context, index) {
            final config = configs[index];
            final isUpdating = automationState.isUpdating[config.id] ?? false;
            
            // Convert AutomationConfig back to Map for NewAutomationCard
            final cardData = _convertConfigToCardData(config, formatHelper);
            
            return NewAutomationCard(
              type: config.configType == 'reminder' ? 'reminder' : 'eviction',
              data: cardData,
              onTap: null, // Disable tap to prevent navigation
              onToggle: () => onToggleConfig(config.id, !config.isActive),
              onDelete: () => onDeleteConfig(config),
              isLoading: isUpdating,
            );
          },
        );
      },
    );
  }

  // Convert AutomationConfig to Map for compatibility with existing NewAutomationCard
  Map<String, dynamic> _convertConfigToCardData(AutomationConfig config, FormatHelper formatHelper) {
    return {
      'id': config.id,
      'type': config.configType,
      'title': config.name,
      'description': config.notificationMessage ?? '',
      'isActive': config.isActive,
      'createdAt': config.formattedCreatedAt,
      'duration': config.duration ?? 0,
      'time': config.duration ?? 0, // For reminder compatibility
      'rule': config.rule ?? '',
      'workspaceName': 'Mặc định', // TODO: Get actual workspace name from organizationId
      'hourFrame': config.hourFrame ?? [],
      'weekdays': config.weekdays ?? [],
      'stages': config.stages ?? [],
      'notifications': config.notifications ?? [],
      'statistics': config.statistics, // Real eviction statistics
      'Report': config.report, // Real reminder report data
      'report': config.report, // Alternative case
      'repeat': config.repeat ?? 0,
      'Repeat': config.repeatTime ?? 0,
      'minutes': config.configType == 'reminder' ? config.duration ?? 30 : null,
      'hours': config.configType == 'eviction' ? (config.duration ?? 1440) ~/ 60 : null,
    };
  }

  int _getCrossAxisCount(double width) {
    if (width < 600) return 1;  // Mobile
    if (width < 1200) return 2; // Tablet
    return 3; // Desktop
  }
  
  double _getChildAspectRatio(double width) {
    // Tính toán dựa trên width và height dự kiến của card
    // Card height estimate:
    // - Header row (badge + icons + switch): ~31px 
    // - SizedBox: 6px
    // - Title (max 2 lines): ~36px (18px per line)
    // - SizedBox: 4px
    // - Workspace text: ~18px
    // - Statistics area: ~28px (including spacing)
    // - Container padding: 8px * 2 = 16px
    // Total: ~139px
    
    final double itemWidth = _getItemWidth(width);
    final double estimatedHeight = 150; // More padding for comfortable spacing
    
    return itemWidth / estimatedHeight;
  }
  
  double _getItemWidth(double width) {
    final crossAxisCount = _getCrossAxisCount(width);
    final spacing = 16.0 * (crossAxisCount - 1); // Spacing between items
    final padding = 32.0; // Left and right padding
    return (width - spacing - padding) / crossAxisCount;
  }
} 