import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../models/stage.dart';
import '../../../../../../../providers/stage_provider.dart';

class StageSelect extends ConsumerStatefulWidget {
  final Stage? stage;
  final Function(Stage) setStage;
  final bool isShowIcon;
  final String orgId;
  final String workspaceId;

  const StageSelect({
    super.key,
    this.stage,
    required this.setStage,
    required this.orgId,
    required this.workspaceId,
    this.isShowIcon = true,
  });

  @override
  ConsumerState<StageSelect> createState() => _StageSelectState();
}

class _StageSelectState extends ConsumerState<StageSelect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
    
    // Delay việc gọi API sau khi widget tree đã build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStages();
    });
  }

  Future<void> _initializeStages() async {
    await ref.read(stageProvider.notifier).fetchStages(widget.orgId, widget.workspaceId);
  }

  void _showStageBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StageSelectBottomSheet(
        currentStage: widget.stage,
        onStageSelected: widget.setStage,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _animation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showStageBottomSheet,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isShowIcon) ...[
                    Image.asset(
                      "assets/images/select_stage_icon.png",
                      height: 25,
                      width: 25,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.stage?.name ?? "Chọn trạng thái",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StageSelectBottomSheet extends ConsumerStatefulWidget {
  final Stage? currentStage;
  final Function(Stage) onStageSelected;

  const StageSelectBottomSheet({
    super.key,
    this.currentStage,
    required this.onStageSelected,
  });

  @override
  ConsumerState<StageSelectBottomSheet> createState() => _StageSelectBottomSheetState();
}

class _StageSelectBottomSheetState extends ConsumerState<StageSelectBottomSheet> {
  String? expandedGroupId;

  Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final stageState = ref.watch(stageProvider);
    final stageNotifier = ref.read(stageProvider.notifier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Trạng thái",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.black12),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Builder(
                    builder: (context) {
                      // Lọc các nhóm không bị ẩn
                      final filteredGroups = stageState.stageGroups
                          .where((group) => !stageNotifier.isGroupHidden(group.id))
                          .toList();

                      return ExpansionPanelList(
                        elevation: 0,
                        expandedHeaderPadding: EdgeInsets.zero,
                        materialGapSize: 0,
                        expansionCallback: (index, isExpanded) {
                          setState(() {
                            final groupId = filteredGroups[index].id;
                            if (expandedGroupId == groupId) {
                              expandedGroupId = null;
                            } else {
                              expandedGroupId = groupId;
                            }
                          });
                        },
                        children: filteredGroups.map((groupWithStages) {
                          // Lọc các trạng thái không bị ẩn trong nhóm
                          final filteredStages = groupWithStages.stages
                              .where((stage) => !stageNotifier.isStageHidden(stage.id))
                              .toList();

                          return ExpansionPanel(
                            backgroundColor: Colors.white,
                            headerBuilder: (context, isExpanded) {
                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                title: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: hexToColor(groupWithStages.hexCode),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      groupWithStages.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              );
                            },
                            body: Column(
                              children: [
                                ...filteredStages
                                    .map<Widget>(
                                      (stage) => Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey[200]!,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: ListTile(
                                          dense: true,
                                          visualDensity:
                                              const VisualDensity(vertical: -2),
                                          tileColor: Colors.white,
                                          selectedTileColor: Colors.grey[100],
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 32),
                                          leading: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: hexToColor(groupWithStages.hexCode),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          title: Text(stage.name),
                                          selected: widget.currentStage?.id == stage.id,
                                          onTap: () {
                                            widget.onStageSelected(stage);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                            isExpanded: expandedGroupId == groupWithStages.id,
                            canTapOnHeader: true,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
