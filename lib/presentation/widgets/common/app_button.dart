import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outline, text, danger }

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDanger;
  final AppButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDanger = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.width,
    this.height,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveVariant = widget.isDanger ? AppButtonVariant.danger : widget.variant;

    Widget childContent;
    if (widget.isLoading) {
      childContent = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else {
      childContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: AppSizes.iconSm),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              widget.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      );
    }

    Widget buttonWidget;
    switch (effectiveVariant) {
      case AppButtonVariant.primary:
        buttonWidget = Container(
          decoration: BoxDecoration(
            gradient: widget.onPressed == null
                ? null
                : LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: AppRadius.radiusLg,
            boxShadow: widget.onPressed == null
                ? null
                : [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
            ),
            onPressed: widget.isLoading ? null : widget.onPressed,
            child: childContent,
          ),
        );
        break;
      case AppButtonVariant.secondary:
        buttonWidget = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceContainer,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
          ),
          onPressed: widget.isLoading ? null : widget.onPressed,
          child: childContent,
        );
        break;
      case AppButtonVariant.outline:
        buttonWidget = OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
          ),
          onPressed: widget.isLoading ? null : widget.onPressed,
          child: childContent,
        );
        break;
      case AppButtonVariant.text:
        buttonWidget = TextButton(
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
          ),
          onPressed: widget.isLoading ? null : widget.onPressed,
          child: childContent,
        );
        break;
      case AppButtonVariant.danger:
        buttonWidget = Container(
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: AppRadius.radiusLg,
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
            ),
            onPressed: widget.isLoading ? null : widget.onPressed,
            child: childContent,
          ),
        );
        break;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: widget.width ?? double.infinity,
          height: widget.height ?? AppSizes.buttonHeightMd,
          child: buttonWidget,
        ),
      ),
    );
  }
}
