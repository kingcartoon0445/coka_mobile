import 'package:flutter/material.dart';
import '../../constants/automation_colors.dart';

class AutomationCardBase extends StatefulWidget {
  final bool isActive;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  
  const AutomationCardBase({
    super.key,
    required this.isActive,
    required this.child,
    this.onTap,
    this.onDelete,
  });
  
  @override
  State<AutomationCardBase> createState() => _AutomationCardBaseState();
}

class _AutomationCardBaseState extends State<AutomationCardBase>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              elevation: _elevationAnimation.value,
              color: widget.isActive 
                  ? AutomationColors.cardActive 
                  : AutomationColors.cardInactive,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: Stack(
                    children: [
                      widget.child,
                      if (widget.onDelete != null)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: AnimatedOpacity(
                            opacity: _isHovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: _DeleteButton(
                              onPressed: widget.onDelete!,
                              isActive: widget.isActive,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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

class _DeleteButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;
  
  const _DeleteButton({
    required this.onPressed,
    required this.isActive,
  });
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        Icons.delete_outline,
        color: AutomationColors.deleteButton,
        size: 20,
      ),
      style: IconButton.styleFrom(
        backgroundColor: isActive 
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        minimumSize: const Size(32, 32),
      ),
    );
  }
} 