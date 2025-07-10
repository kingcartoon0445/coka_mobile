import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DateFilterType {
  today,
  yesterday,
  last7Days,
  last30Days,
  thisYear,
  allTime,
  custom
}

class DatePickerBtn extends StatelessWidget {
  static const _dateFormat = "dd-MM-yyyy";
  static const _textStyle = TextStyle(
    color: Colors.black,
    fontSize: 14,
  );
  static const _selectedTextStyle = TextStyle(
    color: Color(0xFF2C160C),
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueNotifier<String> dateString;
  final Function(DateTime? fromDate, DateTime? toDate)? onDateChanged;
  final bool isExpanded;
  final bool hideBg;

  const DatePickerBtn({
    super.key,
    this.fromDate,
    this.toDate,
    required this.dateString,
    this.onDateChanged,
    this.isExpanded = false,
    this.hideBg = false,
  });

  void _handleDateChange(DateTime from, DateTime to, String label) {
    dateString.value = label;
    onDateChanged?.call(from, to);
  }

  MenuItemButton _buildMenuItem(
    String label,
    DateFilterType type,
    BuildContext context,
  ) {
    return MenuItemButton(
      child: Text(label, style: _textStyle),
      onPressed: () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        switch (type) {
          case DateFilterType.today:
            _handleDateChange(
              today,
              today.add(const Duration(days: 1)),
              label,
            );
          case DateFilterType.yesterday:
            _handleDateChange(
              today.subtract(const Duration(days: 1)),
              today,
              label,
            );
          case DateFilterType.last7Days:
            _handleDateChange(
              now.subtract(const Duration(days: 7)),
              now.add(const Duration(days: 1)),
              label,
            );
          case DateFilterType.last30Days:
            _handleDateChange(
              now.subtract(const Duration(days: 30)),
              now.add(const Duration(days: 1)),
              label,
            );
          case DateFilterType.thisYear:
            _handleDateChange(
              now.subtract(const Duration(days: 365)),
              now.add(const Duration(days: 1)),
              label,
            );
          case DateFilterType.allTime:
            _handleDateChange(
              now.subtract(const Duration(days: 10000)),
              now.add(const Duration(days: 10000)),
              label,
            );
          case DateFilterType.custom:
            _showCustomDatePicker(context);
        }
      },
    );
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    final dateRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now().add(const Duration(days: 1)),
      ),
      firstDate: DateTime(2018),
      lastDate: DateTime(2030),
    );

    if (dateRange != null) {
      final label =
          "${DateFormat(_dateFormat).format(dateRange.start)} đến ${DateFormat(_dateFormat).format(dateRange.end)}";
      _handleDateChange(dateRange.start, dateRange.end, label);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        maximumSize: WidgetStatePropertyAll(
          Size(MediaQuery.of(context).size.width - 32, 350),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 30),
        ),
      ),
      menuChildren: [
        _buildMenuItem("Hôm nay", DateFilterType.today, context),
        _buildMenuItem("Hôm qua", DateFilterType.yesterday, context),
        _buildMenuItem("7 ngày qua", DateFilterType.last7Days, context),
        _buildMenuItem("30 ngày qua", DateFilterType.last30Days, context),
        _buildMenuItem("Năm nay", DateFilterType.thisYear, context),
        _buildMenuItem("Toàn bộ thời gian", DateFilterType.allTime, context),
        _buildMenuItem(
          "Phạm vi ngày tùy chỉnh${isExpanded ? "                                                          " : ""}",
          DateFilterType.custom,
          context,
        ),
      ],
      builder: (context, menuController, child) => InkWell(
        onTap: () {
          menuController.isOpen
              ? menuController.close()
              : menuController.open();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: isExpanded ? MediaQuery.of(context).size.width - 32 : null,
          padding: isExpanded
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: hideBg ? null : const Color(0xFFE3DFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD0D5DD)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month,
                color: Color(0xFF5C33F0),
                size: 20,
              ),
              const SizedBox(width: 4),
              ValueListenableBuilder<String>(
                valueListenable: dateString,
                builder: (context, value, child) => Text(
                  value,
                  style: _selectedTextStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
