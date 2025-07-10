import 'package:flutter/material.dart';
import '../../../../../constants/dialog_colors.dart';
import '../../../../../models/automation_scenario.dart';
import 'simple_scenario_card.dart';

class AutomationScenarioDialog extends StatefulWidget {
  const AutomationScenarioDialog({super.key});
  
  @override
  State<AutomationScenarioDialog> createState() => _AutomationScenarioDialogState();
}

class _AutomationScenarioDialogState extends State<AutomationScenarioDialog>
    with TickerProviderStateMixin {
  late AnimationController _dialogController;
  late AnimationController _cardsController;
  late Animation<double> _dialogAnimation;
  late Animation<double> _overlayAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }
  
  void _setupAnimations() {
    _dialogController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _dialogAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dialogController,
      curve: Curves.easeOutBack,
    ));
    
    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dialogController,
      curve: Curves.easeOut,
    ));
  }
  
  void _startAnimations() {
    _dialogController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _cardsController.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _dialogController.dispose();
    _cardsController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dialogController,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Overlay
              FadeTransition(
                opacity: _overlayAnimation,
                child: GestureDetector(
                  onTap: () => _closeDialog(),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: DialogColors.overlayBackground,
                  ),
                ),
              ),
              
              // Dialog Content
              Center(
                child: ScaleTransition(
                  scale: _dialogAnimation,
                  child: _DialogContent(
                    cardsController: _cardsController,
                    onScenarioSelected: (scenarioType) {
                      Navigator.of(context).pop(scenarioType);
                    },
                    onClose: _closeDialog,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _closeDialog() {
    _dialogController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}

class _DialogContent extends StatelessWidget {
  final AnimationController cardsController;
  final Function(String)? onScenarioSelected;
  final VoidCallback onClose;
  
  const _DialogContent({
    required this.cardsController,
    this.onScenarioSelected,
    required this.onClose,
  });
  
  @override
  Widget build(BuildContext context) {
    final scenarios = _getScenarios();
    final screenSize = MediaQuery.of(context).size;
    
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: screenSize.height * 0.8,
      ),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _DialogHeader(onClose: onClose),
          
          // Content với Flexible để tránh overflow
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: _ScenarioGrid(
                scenarios: scenarios,
                cardsController: cardsController,
                onScenarioSelected: onScenarioSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<AutomationScenario> _getScenarios() {
    return [
      AutomationScenario(
        id: 'recall',
        title: 'Thu hồi khách hàng',
        description: 'Thu hồi khách hàng sau một khoảng thời gian không có phản hồi',
        icon: Icons.assignment_return,
        color: DialogColors.iconPrimary,
      ),
      AutomationScenario(
        id: 'reminder',
        title: 'Nhắc hẹn chăm sóc',
        description: 'Nhắc nhở cập nhật trạng thái sau khi tiếp nhận khách hàng',
        icon: Icons.alarm_on,
        color: DialogColors.iconSecondary,
      ),
    ];
  }
}

class _DialogHeader extends StatelessWidget {
  final VoidCallback onClose;
  
  const _DialogHeader({required this.onClose});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF3F4F6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Chọn kịch bản Automation',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF9FAFB),
              foregroundColor: const Color(0xFF6B7280),
              padding: const EdgeInsets.all(10),
              minimumSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioGrid extends StatelessWidget {
  final List<AutomationScenario> scenarios;
  final AnimationController cardsController;
  final Function(String)? onScenarioSelected;
  
  const _ScenarioGrid({
    required this.scenarios,
    required this.cardsController,
    this.onScenarioSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: scenarios.asMap().entries.map((entry) {
        final index = entry.key;
        final scenario = entry.value;
        
        return Container(
          margin: EdgeInsets.only(bottom: index < scenarios.length - 1 ? 16 : 0),
          height: 120, // Fixed height cho mỗi card
          child: SimpleScenarioCard(
            scenario: scenario,
            animationController: cardsController,
            animationDelay: Duration(milliseconds: index * 100),
            onTap: () => onScenarioSelected?.call(scenario.id),
          ),
        );
      }).toList(),
    );
  }
} 