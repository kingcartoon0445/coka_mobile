import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Model cho time configuration
class TimeConfig {
  final int hours;
  final int minutes;

  const TimeConfig({
    required this.hours,
    required this.minutes,
  });

  TimeConfig copyWith({
    int? hours,
    int? minutes,
  }) {
    return TimeConfig(
      hours: hours ?? this.hours,
      minutes: minutes ?? this.minutes,
    );
  }

  /// Tổng số phút
  int get totalMinutes => hours * 60 + minutes;

  /// Format hiển thị
  String get displayText {
    if (hours > 0 && minutes > 0) {
      return '$hours giờ $minutes phút';
    } else if (hours > 0) {
      return '$hours giờ';
    } else if (minutes > 0) {
      return '$minutes phút';
    } else {
      return 'Ngay lập tức';
    }
  }

  static TimeConfig fromMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return TimeConfig(hours: hours, minutes: minutes);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeConfig &&
          runtimeType == other.runtimeType &&
          hours == other.hours &&
          minutes == other.minutes;

  @override
  int get hashCode => hours.hashCode ^ minutes.hashCode;
}

/// Time selector với interactive styling
class TimeSelector extends StatelessWidget {
  final TimeConfig timeConfig;
  final Function(TimeConfig) onTimeChanged;
  final bool isLoading;

  const TimeSelector({
    super.key,
    required this.timeConfig,
    required this.onTimeChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : () => _showTimePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(4),
          color: const Color(0xFF3B82F6).withOpacity(0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            else
              Text(
                timeConfig.displayText,
                style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            if (!isLoading) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.access_time,
                color: Color(0xFF3B82F6),
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTimePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TimePickerDialog(
        initialTimeConfig: timeConfig,
        onTimeSelected: onTimeChanged,
      ),
    );
  }
}

/// Dialog cho việc chọn thời gian chi tiết
class TimePickerDialog extends StatefulWidget {
  final TimeConfig initialTimeConfig;
  final Function(TimeConfig) onTimeSelected;

  const TimePickerDialog({
    super.key,
    required this.initialTimeConfig,
    required this.onTimeSelected,
  });

  @override
  State<TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<TimePickerDialog> {
  late TextEditingController hoursController;
  late TextEditingController minutesController;
  late TimeConfig currentTimeConfig;

  // Predefined quick options
  final List<TimeConfig> quickOptions = [
    const TimeConfig(hours: 0, minutes: 15),
    const TimeConfig(hours: 0, minutes: 30),
    const TimeConfig(hours: 1, minutes: 0),
    const TimeConfig(hours: 2, minutes: 0),
    const TimeConfig(hours: 4, minutes: 0),
    const TimeConfig(hours: 8, minutes: 0),
    const TimeConfig(hours: 12, minutes: 0),
    const TimeConfig(hours: 24, minutes: 0),
    const TimeConfig(hours: 48, minutes: 0),
    const TimeConfig(hours: 72, minutes: 0),
  ];

  @override
  void initState() {
    super.initState();
    currentTimeConfig = widget.initialTimeConfig;
    hoursController = TextEditingController(text: currentTimeConfig.hours.toString());
    minutesController = TextEditingController(text: currentTimeConfig.minutes.toString());
  }

  @override
  void dispose() {
    hoursController.dispose();
    minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn thời gian'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick options
            const Text(
              'Chọn nhanh:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quickOptions.map((option) {
                final isSelected = option == currentTimeConfig;
                return GestureDetector(
                  onTap: () => _selectTimeOption(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      option.displayText,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Custom input
            const Text(
              'Hoặc nhập tùy chỉnh:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: hoursController,
                    decoration: const InputDecoration(
                      labelText: 'Giờ',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: _updateCustomTime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: minutesController,
                    decoration: const InputDecoration(
                      labelText: 'Phút',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onChanged: _updateCustomTime,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                'Thời gian đã chọn: ${currentTimeConfig.displayText}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onTimeSelected(currentTimeConfig);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
          ),
          child: const Text('Chọn'),
        ),
      ],
    );
  }

  void _selectTimeOption(TimeConfig option) {
    setState(() {
      currentTimeConfig = option;
      hoursController.text = option.hours.toString();
      minutesController.text = option.minutes.toString();
    });
  }

  void _updateCustomTime(String value) {
    final hours = int.tryParse(hoursController.text) ?? 0;
    final minutes = int.tryParse(minutesController.text) ?? 0;
    
    // Validate minutes
    final validMinutes = minutes > 59 ? 59 : minutes;
    if (validMinutes != minutes) {
      minutesController.text = validMinutes.toString();
    }
    
    setState(() {
      currentTimeConfig = TimeConfig(hours: hours, minutes: validMinutes);
    });
  }
} 