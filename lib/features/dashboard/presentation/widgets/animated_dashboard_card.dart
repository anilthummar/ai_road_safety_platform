import 'package:ai_road_safety_platform/core/constants/app_dimensions.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:flutter/material.dart';

/// Premium Material 3 card with entrance animation and optional accent border.
class AnimatedDashboardCard extends StatefulWidget {
  /// Card body.
  final Widget child;

  /// Stagger delay for cascade entrance.
  final Duration delay;

  /// Optional accent border color.
  final Color? accentColor;

  /// Inner padding.
  final EdgeInsetsGeometry? padding;

  /// Creates [AnimatedDashboardCard].
  const AnimatedDashboardCard({
    required this.child,
    this.delay = Duration.zero,
    this.accentColor,
    this.padding,
    super.key,
  });

  @override
  State<AnimatedDashboardCard> createState() => _AnimatedDashboardCardState();
}

class _AnimatedDashboardCardState extends State<AnimatedDashboardCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.accentColor;
    // Soft accent-tinted surface makes state readable at a glance.
    final surface = accent == null
        ? scheme.surfaceContainerLow
        : Color.alphaBlend(
            accent.withValues(alpha: 0.05),
            scheme.surfaceContainerLow,
          );

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            side: BorderSide(
              color: accent?.withValues(alpha: 0.55) ??
                  scheme.outlineVariant.withValues(alpha: 0.55),
              width: accent != null ? 1.4 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
