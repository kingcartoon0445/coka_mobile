import 'package:flutter/material.dart';

/// Base model cho selectable items
class SelectableItem {
  final String id;
  final String label;
  final bool isSelected;
  final Color? color;

  const SelectableItem({
    required this.id,
    required this.label,
    this.isSelected = false,
    this.color,
  });

  SelectableItem copyWith({
    String? id,
    String? label,
    bool? isSelected,
    Color? color,
  }) {
    return SelectableItem(
      id: id ?? this.id,
      label: label ?? this.label,
      isSelected: isSelected ?? this.isSelected,
      color: color ?? this.color,
    );
  }
}

/// Multi-select popover cho các loại selector khác nhau
class MultiSelectPopover extends StatelessWidget {
  final List<SelectableItem> items;
  final List<String> selectedIds;
  final Function(List<String>) onSelectionChanged;
  final String placeholder;
  final String title;
  final bool isLoading;
  final int maxDisplayItems;

  const MultiSelectPopover({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.placeholder,
    required this.title,
    this.isLoading = false,
    this.maxDisplayItems = 3,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      enabled: !isLoading && items.isNotEmpty,
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          enabled: false,
          child: SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                ...items.map((item) => _buildCheckboxItem(item)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        onSelectionChanged([]);
                        Navigator.pop(context);
                      },
                      child: const Text('Bỏ chọn tất cả'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
      child: _buildSelector(context),
    );
  }

  Widget _buildCheckboxItem(SelectableItem item) {
    return StatefulBuilder(
      builder: (context, setState) {
        final isSelected = selectedIds.contains(item.id);
        
        return CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: isSelected,
          onChanged: (bool? value) {
            final newSelectedIds = List<String>.from(selectedIds);
            if (value == true) {
              if (!newSelectedIds.contains(item.id)) {
                newSelectedIds.add(item.id);
              }
            } else {
              newSelectedIds.remove(item.id);
            }
            onSelectionChanged(newSelectedIds);
            setState(() {});
          },
          title: Row(
            children: [
              if (item.color != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelector(BuildContext context) {
    return Container(
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
            Flexible(
              child: Text(
                _getDisplayText(),
                style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (!isLoading) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF3B82F6),
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  String _getDisplayText() {
    if (selectedIds.isEmpty) {
      return placeholder;
    }

    final selectedItems = items.where((item) => selectedIds.contains(item.id)).toList();
    
    if (selectedItems.length <= maxDisplayItems) {
      return selectedItems.map((item) => item.label).join(', ');
    }
    
    final displayItems = selectedItems.take(maxDisplayItems).map((item) => item.label).join(', ');
    final remainingCount = selectedItems.length - maxDisplayItems;
    
    return '$displayItems và $remainingCount mục khác';
  }
}

/// Specialized selectors for different types

/// Category Selector
class CategorySelector extends StatelessWidget {
  final List<SelectableItem> categories;
  final List<String> selectedCategoryIds;
  final Function(List<String>) onSelectionChanged;
  final bool isLoading;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryIds,
    required this.onSelectionChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSelectPopover(
      items: categories,
      selectedIds: selectedCategoryIds,
      onSelectionChanged: onSelectionChanged,
      placeholder: 'tất cả phân loại',
      title: 'Chọn phân loại',
      isLoading: isLoading,
    );
  }
}

/// Source Selector
class SourceSelector extends StatelessWidget {
  final List<SelectableItem> sources;
  final List<String> selectedSourceIds;
  final Function(List<String>) onSelectionChanged;
  final bool isLoading;

  const SourceSelector({
    super.key,
    required this.sources,
    required this.selectedSourceIds,
    required this.onSelectionChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSelectPopover(
      items: sources,
      selectedIds: selectedSourceIds,
      onSelectionChanged: onSelectionChanged,
      placeholder: 'tất cả nguồn',
      title: 'Chọn nguồn',
      isLoading: isLoading,
    );
  }
}

/// Stage Selector
class StageSelector extends StatelessWidget {
  final List<SelectableItem> stages;
  final List<String> selectedStageIds;
  final Function(List<String>) onSelectionChanged;
  final bool isLoading;

  const StageSelector({
    super.key,
    required this.stages,
    required this.selectedStageIds,
    required this.onSelectionChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSelectPopover(
      items: stages,
      selectedIds: selectedStageIds,
      onSelectionChanged: onSelectionChanged,
      placeholder: 'tất cả trạng thái',
      title: 'Chọn trạng thái',
      isLoading: isLoading,
    );
  }
} 