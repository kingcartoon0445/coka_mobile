import 'package:coka/pages/organization/detail_organization/workspace/customers/widgets/assignee_selection_dialog.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/widgets/chip_input.dart';
import '../../../../../../shared/widgets/date_picker_btn.dart';
import '../../../../../../api/repositories/workspace_repository.dart';
import '../../../../../../api/api_client.dart';
import '../../../../../../shared/widgets/avatar_widget.dart';

class Rating extends ChipData {
  Rating({required String id, required String name}) : super(id, name);
}

class Tag extends ChipData {
  Tag({required String name}) : super(name, name);
}

class Source extends ChipData {
  Source({required String name}) : super(name, name);
}

class Category extends ChipData {
  Category({required String id, required String name}) : super(id, name);
}

class FilterResult {
  final List<AssigneeData> assignees;
  final List<Category> categories;
  final List<Source> sources;
  final List<Tag> tags;
  final List<Rating> ratings;
  final DateTimeRange? dateRange;

  FilterResult({
    required this.assignees,
    required this.categories,
    required this.sources,
    required this.tags,
    required this.ratings,
    this.dateRange,
  });

  bool get hasActiveFilters {
    return assignees.isNotEmpty ||
        categories.isNotEmpty ||
        sources.isNotEmpty ||
        tags.isNotEmpty ||
        ratings.isNotEmpty ||
        dateRange != null;
  }

  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {};

    if (dateRange != null) {
      params['startDate'] = dateRange!.start.toIso8601String();
      params['endDate'] = dateRange!.end.toIso8601String();
    }

    if (categories.isNotEmpty) {
      categories.asMap().forEach((index, category) {
        params['categoryList[$index]'] = category.id;
      });
    }

    if (sources.isNotEmpty) {
      sources.asMap().forEach((index, source) {
        params['sourceList[$index]'] = source.name;
      });
    }

    if (ratings.isNotEmpty) {
      ratings.asMap().forEach((index, rating) {
        params['rating[$index]'] = rating.id;
      });
    }

    if (tags.isNotEmpty) {
      tags.asMap().forEach((index, tag) {
        params['tags[$index]'] = tag.name;
      });
    }

    if (assignees.isNotEmpty) {
      int assignToIndex = 0;
      int teamIdIndex = 0;

      for (var assignee in assignees) {
        if (assignee.isTeam) {
          params['teamId[$teamIdIndex]'] = assignee.id;
          teamIdIndex++;
        } else {
          params['assignTo[$assignToIndex]'] = assignee.id;
          assignToIndex++;
        }
      }
    }

    return params;
  }
}

class FilterModal extends StatefulWidget {
  final String organizationId;
  final String workspaceId;
  final FilterResult? initialValue;

  const FilterModal({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    this.initialValue,
  });

  static Future<FilterResult?> show(
    BuildContext context,
    String organizationId,
    String workspaceId, {
    FilterResult? initialValue,
  }) {
    return showModalBottomSheet<FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FilterModal(
        organizationId: organizationId,
        workspaceId: workspaceId,
        initialValue: initialValue,
      ),
    );
  }

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  static const _titleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF101828),
  );

  static const _chipLabelStyle = TextStyle(
    fontSize: 12,
    color: Color(0xFF344054),
  );

  static final _inputDecoration = InputDecoration(
    hintText: 'Tất cả',
    suffixIcon: const Icon(Icons.keyboard_arrow_down, color: AppColors.text, size: 20),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
    ),
  );

  final List<AssigneeData> _selectedAssignees = [];
  List<Category> _selectedCategories = [];
  List<Source> _selectedSources = [];
  List<Source> _sources = [];
  List<Tag> _selectedTags = [];
  List<Tag> _tags = [];
  List<Rating> _selectedRatings = [];
  late final WorkspaceRepository _workspaceRepository;
  final ValueNotifier<String> _dateString =
      ValueNotifier<String>('Toàn bộ thời gian');
  final ValueNotifier<List<AssigneeData>> _assigneesNotifier =
      ValueNotifier<List<AssigneeData>>([]);
  final ValueNotifier<bool> _resetNotifier = ValueNotifier<bool>(false);
  DateTimeRange? _selectedDateRange;
  bool _isLoadingTags = true;
  bool _isLoadingSources = true;

  final List<Category> _categories = [
    Category(
      id: 'ce7f42cf-f10f-49d2-b57e-0c75f8463c82',
      name: 'Nhập vào',
    ),
    Category(
      id: '3b70970b-e448-46fa-af8f-6605855a6b52',
      name: 'Form',
    ),
    Category(
      id: '38b353c3-ecc8-4c62-be27-229ef47e622d',
      name: 'AIDC',
    ),
  ];

  final List<Rating> _ratings = [
    Rating(id: '0', name: 'Chưa đánh giá'),
    Rating(id: '1', name: '1 sao'),
    Rating(id: '2', name: '2 sao'),
    Rating(id: '3', name: '3 sao'),
    Rating(id: '4', name: '4 sao'),
    Rating(id: '5', name: '5 sao'),
  ];

  @override
  void initState() {
    super.initState();
    _workspaceRepository = WorkspaceRepository(ApiClient());
    if (widget.initialValue != null) {
      _selectedAssignees.addAll(widget.initialValue!.assignees);
      _assigneesNotifier.value = List.from(widget.initialValue!.assignees);
      _selectedCategories = List.from(widget.initialValue!.categories);
      _selectedSources = List.from(widget.initialValue!.sources);
      _selectedTags = List.from(widget.initialValue!.tags);
      _selectedRatings = List.from(widget.initialValue!.ratings);
      _selectedDateRange = widget.initialValue!.dateRange;
      if (_selectedDateRange != null) {
        _dateString.value =
            '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}';
      }
    }
    _loadTags();
    _loadSources();
  }

  @override
  void dispose() {
    _dateString.dispose();
    _assigneesNotifier.dispose();
    _resetNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    try {
      final response = await _workspaceRepository.getTagList(
        widget.organizationId,
        widget.workspaceId,
      );
      if (mounted) {
        setState(() {
          _tags = (response['content'] as List)
              .map((tag) => Tag(name: tag.toString()))
              .toList();
          _isLoadingTags = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTags = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi tải danh sách nhãn')),
        );
      }
    }
  }

  Future<void> _loadSources() async {
    try {
      final response = await _workspaceRepository.getSourceList(
        widget.organizationId,
        widget.workspaceId,
      );
      if (mounted) {
        setState(() {
          _sources = (response['content'] as List)
              .map((source) => Source(name: source.toString()))
              .toList();
          _isLoadingSources = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSources = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Có lỗi xảy ra khi tải danh sách nguồn')),
        );
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedAssignees.clear();
      _assigneesNotifier.value = [];
      _selectedCategories = [];
      _selectedSources = [];
      _selectedTags = [];
      _selectedRatings = [];
      _selectedDateRange = null;
      _dateString.value = 'Toàn bộ thời gian';
      _resetNotifier.value = !_resetNotifier.value;
    });
  }

  void _applyFilters() {
    final result = FilterResult(
      assignees: List.from(_selectedAssignees),
      categories: List.from(_selectedCategories),
      sources: List.from(_selectedSources),
      tags: List.from(_selectedTags),
      ratings: List.from(_selectedRatings),
      dateRange: _selectedDateRange,
    );
    Navigator.of(context).pop(result);
  }

  Widget _buildFilterSection({
    required String title,
    required List<AssigneeData> selectedItems,
    required Function(AssigneeData) onItemSelected,
    required Function(AssigneeData) onItemRemoved,
  }) {
    return StatefulBuilder(
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              if (title == 'Đối tượng phụ trách') {
                final selectedAssignees = await AssigneeSelectionDialog.show(
                  context,
                  widget.organizationId,
                  widget.workspaceId,
                  _selectedAssignees,
                );
                if (selectedAssignees != null && mounted) {
                  _selectedAssignees.clear();
                  _selectedAssignees.addAll(selectedAssignees);
                  setState(() {
                    _assigneesNotifier.value = List.from(selectedAssignees);
                  });
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD0D5DD)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ValueListenableBuilder<List<AssigneeData>>(
                      valueListenable: _assigneesNotifier,
                      builder: (context, assignees, _) {
                        return assignees.isEmpty
                            ? const Text(
                                'Tất cả',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.text,
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: assignees.map((item) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F4F7),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AppAvatar(
                                          size: 16,
                                          shape: AvatarShape.circle,
                                          imageUrl: item.avatar,
                                          fallbackText: item.name,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF344054),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () {
                                            onItemRemoved(item);
                                            setState(() {
                                              _assigneesNotifier.value =
                                                  List.from(_selectedAssignees);
                                            });
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Color(0xFF667085),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                      },
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.text,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTagSection() {
    if (_isLoadingTags) {
      return _buildLoadingSection('Nhãn');
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _resetNotifier,
      builder: (context, _, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhãn', style: _titleStyle),
            const SizedBox(height: 8),
            ChipsInput<Tag>(
              key: ValueKey(_resetNotifier.value),
              initialValue: _selectedTags,
              allowInputText: false,
              suggestions: _tags,
              decoration: _inputDecoration,
              onChanged: (List<Tag> data) {
                setState(() {
                  _selectedTags = data;
                });
              },
              chipBuilder: _buildChip,
              suggestionBuilder: (context, state, tag) => _buildSuggestion(
                  context, state, tag, _selectedTags.contains(tag)),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildLoadingSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _titleStyle),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD0D5DD)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text(
                'Đang tải...',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF667085),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildChip<T extends ChipData>(
      BuildContext context, ChipsInputState<T> state, T data) {
    return Chip(
      label: Text(
        data.name,
        style: _chipLabelStyle,
      ),
      backgroundColor: const Color(0xFFF2F4F7),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: () => state.deleteChip(data),
    );
  }

  Widget _buildSuggestion<T extends ChipData>(
    BuildContext context,
    ChipsInputState<T> state,
    T data,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        if (isSelected) {
          state.deleteChip(data);
        } else {
          state.selectSuggestion(data);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? const Color(0xFFF9FAFB) : Colors.transparent,
        alignment: Alignment.centerLeft,
        child: Text(
          data.name,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? AppColors.primary : AppColors.text,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return ValueListenableBuilder<bool>(
      valueListenable: _resetNotifier,
      builder: (context, _, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Đánh giá', style: _titleStyle),
            const SizedBox(height: 8),
            ChipsInput<Rating>(
              key: ValueKey(_resetNotifier.value),
              initialValue: _selectedRatings,
              allowInputText: false,
              suggestions: _ratings,
              decoration: _inputDecoration,
              onChanged: (List<Rating> data) {
                setState(() {
                  _selectedRatings = data;
                });
              },
              chipBuilder: _buildChip,
              suggestionBuilder: (context, state, rating) => _buildSuggestion(
                  context, state, rating, _selectedRatings.contains(rating)),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildCategorySection() {
    return ValueListenableBuilder<bool>(
      valueListenable: _resetNotifier,
      builder: (context, _, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Theo phân loại', style: _titleStyle),
            const SizedBox(height: 8),
            ChipsInput<Category>(
              key: ValueKey(_resetNotifier.value),
              initialValue: _selectedCategories,
              allowInputText: false,
              suggestions: _categories,
              decoration: _inputDecoration,
              onChanged: (List<Category> data) {
                setState(() {
                  _selectedCategories = data;
                });
              },
              chipBuilder: _buildChip,
              suggestionBuilder: (context, state, category) => _buildSuggestion(
                  context,
                  state,
                  category,
                  _selectedCategories.contains(category)),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildSourceSection() {
    if (_isLoadingSources) {
      return _buildLoadingSection('Theo nguồn');
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _resetNotifier,
      builder: (context, _, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Theo nguồn', style: _titleStyle),
            const SizedBox(height: 8),
            ChipsInput<Source>(
              key: ValueKey(_resetNotifier.value),
              initialValue: _selectedSources,
              allowInputText: false,
              suggestions: _sources,
              decoration: _inputDecoration,
              onChanged: (List<Source> data) {
                setState(() {
                  _selectedSources = data;
                });
              },
              chipBuilder: _buildChip,
              suggestionBuilder: (context, state, source) => _buildSuggestion(
                  context, state, source, _selectedSources.contains(source)),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Theo thời gian', style: _titleStyle),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: DatePickerBtn(
            dateString: _dateString,
            isExpanded: false,
            onDateChanged: (fromDate, toDate) {
              setState(() {
                if (fromDate != null && toDate != null) {
                  _selectedDateRange =
                      DateTimeRange(start: fromDate, end: toDate);
                }
              });
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _applyFilters();
        return true;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE4E7EC),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lọc',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text(
                    'Đặt lại',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF667085),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateRangeSection(),
                  _buildFilterSection(
                    title: 'Đối tượng phụ trách',
                    selectedItems: _selectedAssignees,
                    onItemSelected: (item) {
                      setState(() {
                        _selectedAssignees.add(item);
                      });
                    },
                    onItemRemoved: (item) {
                      setState(() {
                        _selectedAssignees.remove(item);
                      });
                    },
                  ),
                  _buildCategorySection(),
                  _buildSourceSection(),
                  _buildTagSection(),
                  _buildRatingSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
