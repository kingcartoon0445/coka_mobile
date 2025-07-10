import 'package:flutter/material.dart';
import '../../models/automation_scenario.dart';
import '../../constants/dialog_colors.dart';

class ScenarioCard extends StatefulWidget {
  final AutomationScenario scenario;
  final AnimationController animationController;
  final Duration animationDelay;
  final VoidCallback? onTap;
  
  const ScenarioCard({
    super.key,
    required this.scenario,
    required this.animationController,
    required this.animationDelay,
    this.onTap,
  });
  
  @override
  State<ScenarioCard> createState() => _ScenarioCardState();
}

class _ScenarioCardState extends State<ScenarioCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startDelayedAnimation();
  }
  
  void _setupAnimations() {
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.easeOutBack,
    ));
  }
  
  void _startDelayedAnimation() {
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        widget.animationController.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: AnimatedBuilder(
              animation: _hoverController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _buildCard(),
                );
              },
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCard() {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered ? DialogColors.cardHover : DialogColors.cardBackground,
            border: Border.all(
              color: DialogColors.cardBorder,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: DialogColors.cardShadow,
                blurRadius: _elevationAnimation.value,
                offset: Offset(0, _elevationAnimation.value / 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.scenario.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.scenario.icon,
                    size: 24,
                    color: widget.scenario.color,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Title
                Text(
                  widget.scenario.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DialogColors.titleColor,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Description
                Expanded(
                  child: Text(
                    widget.scenario.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: DialogColors.descriptionColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }
} 