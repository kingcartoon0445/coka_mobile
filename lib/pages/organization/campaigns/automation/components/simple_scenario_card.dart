import 'package:flutter/material.dart';
import '../../../../../constants/dialog_colors.dart';
import '../../../../../models/automation_scenario.dart';

class SimpleScenarioCard extends StatefulWidget {
  final AutomationScenario scenario;
  final VoidCallback? onTap;
  final Duration animationDelay;
  final AnimationController animationController;
  
  const SimpleScenarioCard({
    super.key,
    required this.scenario,
    this.onTap,
    required this.animationDelay,
    required this.animationController,
  });
  
  @override
  State<SimpleScenarioCard> createState() => _SimpleScenarioCardState();
}

class _SimpleScenarioCardState extends State<SimpleScenarioCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
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
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
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
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.easeOutQuart,
    ));
  }
  
  void _startDelayedAnimation() {
    Future.delayed(widget.animationDelay, () {
      if (mounted && widget.animationController.status != AnimationStatus.completed) {
        // Animation sẽ được trigger từ parent
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
      animation: Listenable.merge([widget.animationController, _hoverController]),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: _buildCard(),
            ),
          ),
        );
      },
    );
  }
  
      Widget _buildCard() {
    return InkWell(
      onTap: widget.onTap,
      onHover: _onHover,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(
            color: _isHovered 
                ? widget.scenario.color.withOpacity(0.4)
                : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.scenario.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.scenario.icon,
                size: 24,
                color: widget.scenario.color,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    widget.scenario.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DialogColors.titleColor,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Description
                  Text(
                    widget.scenario.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: DialogColors.descriptionColor,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Arrow indicator
            AnimatedOpacity(
              opacity: _isHovered ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: widget.scenario.color,
              ),
            ),
          ],
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