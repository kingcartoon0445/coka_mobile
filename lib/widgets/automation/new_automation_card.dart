import 'package:flutter/material.dart';
import '../../constants/automation_colors.dart';
import '../../styles/automation_text_styles.dart';
import 'automation_card_base.dart';
import 'automation_badge.dart';
import 'automation_switch.dart';
import 'statistics_item.dart';

class NewAutomationCard extends StatelessWidget {
  final String type; // 'reminder' or 'eviction'
  final Map<String, dynamic> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final bool isLoading;
  
  const NewAutomationCard({
    super.key,
    required this.type,
    required this.data,
    this.onTap,
    this.onToggle,
    this.onDelete,
    this.isLoading = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final bool isActive = data['isActive'] ?? false;
    final String title = _getTitle();
    final List<StatisticsData> statistics = _getStatistics();
    
    return AutomationCardBase(
      isActive: isActive,
      onTap: onTap,
      onDelete: onDelete,
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Badge + Icons + Switch
            Row(
              children: [
                AutomationBadge(
                  type: type == 'reminder' 
                      ? AutomationBadgeType.reminder 
                      : AutomationBadgeType.recall,
                  isActive: isActive,
                ),
                const SizedBox(width: 8),
                _FeatureIcons(
                  hasWorkingHours: _hasWorkingHours(),
                  hasRepeat: _hasRepeat(),
                  isActive: isActive,
                ),
                const Spacer(),
                AutomationSwitch(
                  value: isActive,
                  onChanged: onToggle != null ? (_) => onToggle!() : null,
                  isActive: isActive,
                  isLoading: isLoading,
                ),
              ],
            ),
            
            const SizedBox(height: 6),
            
            // Content Area - Remove Expanded to prevent overflow
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and description based on type
                if (type == 'reminder') ...[
                  // Reminder format: "title description"
                  Text(
                    '$title ${_getDescription()}',
                    style: AutomationTextStyles.cardTitle(isActive),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  // Eviction format: "title: description"
                  Text(
                    '$title: ${_getDescription()}',
                    style: AutomationTextStyles.cardTitle(isActive),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 4),
                
                // Workspace info
                Text(
                  'Tại không gian làm việc: ${_getWorkspaceName()}',
                  style: AutomationTextStyles.workspaceName(isActive),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Statistics with fixed spacing
                if (statistics.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  StatisticsRow(
                    statistics: statistics,
                    isActive: isActive,
                  ),
                ] else
                  const SizedBox(height: 4), // Small spacer when no statistics
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getTitle() {
    if (type == 'reminder') {
      final durationValue = data['duration'] ?? data['time'] ?? data['minutes'] ?? 30;
      final int minutes = durationValue is String ? int.tryParse(durationValue) ?? 30 : durationValue as int;
      final String duration = _formatDuration(minutes);
      return 'Gửi thông báo sau $duration tiếp nhận khách hàng';
    } else {
      // Eviction rule title format: "Thu hồi Lead sau {duration}"
      final durationValue = data['duration'];
      final hoursValue = data['hours'] ?? 24;
      final int hours = hoursValue is String ? int.tryParse(hoursValue) ?? 24 : hoursValue as int;
      final int minutes = durationValue is String ? int.tryParse(durationValue) ?? (hours * 60) : (durationValue ?? (hours * 60)) as int;
      final String duration = _formatDuration(minutes);
      return 'Thu hồi Lead sau $duration';
    }
  }
  
  String _getDescription() {
    if (type == 'reminder') {
      // Hiển thị thông tin stages nếu có
      final List<dynamic>? stages = data['stages'];
      if (stages == null || stages.isEmpty) {
        return 'thuộc bất kỳ trạng thái';
      }
      
      // TODO: Convert stage IDs to stage names
      // For now, just show generic text
      return 'thuộc bất kỳ trạng thái';
    } else {
      // Eviction: Check stage update information
      return _getStageUpdateText();
    }
  }
  
  String _getStageUpdateText() {
    final List<dynamic>? stages = data['stages'];
    
    if (stages == null || stages.isEmpty) {
      return 'không cập nhật trạng thái chăm sóc';
    }
    
    // Nếu chỉ có 1 stage với ID 00000000-0000-0000-0000-000000000000
    if (stages.length == 1) {
      final stageData = stages[0];
      final String stageId = stageData is Map ? (stageData['stageId'] ?? '') : stageData.toString();
      if (stageId == "00000000-0000-0000-0000-000000000000") {
        return 'không cập nhật trạng thái chăm sóc';
      }
    }
    
    // TODO: Convert stage IDs to actual stage names
    // For now, show generic text
    return 'chuyển trạng thái chăm sóc';
  }
  
  String _getWorkspaceName() {
    // Get workspace name from data, fallback to 'Mặc định'
    final String workspaceName = data['workspaceName'] ?? data['workspace'] ?? 'Mặc định';
    return workspaceName;
  }
  
  List<StatisticsData> _getStatistics() {
    if (type == 'reminder') {
      // Reminder lấy từ Report field
      final List<dynamic>? reportData = data['Report'] ?? data['report'];
      
      if (reportData != null && reportData.isNotEmpty) {
        return reportData.map((stat) {
          final countValue = stat['NumberItem'] ?? stat['numberItem'] ?? stat['count'] ?? 0;
          final count = countValue is String ? int.tryParse(countValue) ?? 0 : countValue as int;
          return StatisticsData(
            name: stat['Name'] ?? stat['name'] ?? '',
            count: count,
          );
        }).toList();
      }
      
      // Fallback for reminder
      return [
        const StatisticsData(name: 'Đã gửi', count: 0),
        const StatisticsData(name: 'Chờ xử lý', count: 0),
      ];
    } else {
      // Eviction lấy từ statistics field
      final List<dynamic>? statisticsData = data['statistics'];
      
      if (statisticsData != null && statisticsData.isNotEmpty) {
        return statisticsData.map((stat) {
          final countValue = stat['numberItem'] ?? stat['count'] ?? 0;
          final count = countValue is String ? int.tryParse(countValue) ?? 0 : countValue as int;
          return StatisticsData(
            name: stat['name'] ?? '',
            count: count,
          );
        }).toList();
      }
      
      // Fallback for eviction
      return [
        const StatisticsData(name: 'Đã hủy', count: 0),
        const StatisticsData(name: 'Chờ thu hồi', count: 0),
        const StatisticsData(name: 'Đã thu hồi', count: 0),
      ];
    }
  }
  
  bool _hasWorkingHours() {
    if (type == 'reminder') {
      // Hiển thị cho mọi reminder config
      return true;
    } else {
      // Eviction: Chỉ hiển thị nếu có hourFrame
      final List<dynamic>? hourFrame = data['hourFrame'];
      return hourFrame != null && hourFrame.isNotEmpty;
    }
  }
  
  bool _hasRepeat() {
    if (type == 'reminder') {
      // Hiển thị cho reminder có repeat > 0
      final repeatValue = data['repeat'] ?? data['Repeat'] ?? 0;
      final repeat = repeatValue is String ? int.tryParse(repeatValue) ?? 0 : repeatValue as int;
      return repeat > 0;
    } else {
      // Eviction: Hiển thị nếu có notifications
      final List<dynamic>? notifications = data['notifications'];
      return notifications != null && notifications.isNotEmpty;
    }
  }
  
  String _formatDuration(int minutes) {
    if (minutes == 0) return '0 phút';
    
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours == 0) return '$mins phút';
    if (mins == 0) return '$hours giờ';
    return '$hours giờ $mins phút';
  }
}

class _FeatureIcons extends StatelessWidget {
  final bool hasWorkingHours;
  final bool hasRepeat;
  final bool isActive;
  
  const _FeatureIcons({
    required this.hasWorkingHours,
    required this.hasRepeat,
    required this.isActive,
  });
  
  @override
  Widget build(BuildContext context) {
    final iconColor = isActive 
        ? AutomationColors.textOnPrimary 
        : AutomationColors.textSecondary;
    
    return Row(
      children: [
        if (hasWorkingHours)
          Tooltip(
            message: 'Chỉ hoạt động trong giờ làm việc',
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                Icons.access_time,
                size: 16,
                color: iconColor,
              ),
            ),
          ),
        if (hasRepeat)
          Tooltip(
            message: 'Lặp lại nhiều lần',
            child: Icon(
              Icons.loop,
              size: 16,
              color: iconColor,
            ),
          ),
      ],
    );
  }
} 