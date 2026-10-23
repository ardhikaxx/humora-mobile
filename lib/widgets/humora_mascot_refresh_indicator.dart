import 'dart:math' as math;
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import '../core/services/vibration_service.dart';
import '../core/theme/app_colors.dart';

/// Pull-to-refresh widget with interactive mascot "Si Humo" animation.
///
/// Displays a peeking mascot that tilts playfully when dragged, bounces happily
/// when refreshing, and provides subtle haptic feedback on arming and completion.
class HumoraMascotRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final IndicatorController? controller;
  final double offsetToArmed;
  final String draggingText;
  final String armedText;
  final String loadingText;
  final String completeText;

  const HumoraMascotRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.controller,
    this.offsetToArmed = 96.0,
    this.draggingText = 'Tarik untuk tawa segar...',
    this.armedText = 'Lepas untuk Si Humo! 🎉',
    this.loadingText = 'Menyiapkan tawa segar...',
    this.completeText = 'Tawa siap disajikan! ✨',
  });

  @override
  State<HumoraMascotRefreshIndicator> createState() =>
      _HumoraMascotRefreshIndicatorState();
}

class _HumoraMascotRefreshIndicatorState
    extends State<HumoraMascotRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleStateChanged(IndicatorStateChange change) {
    if (change.didChange(to: IndicatorState.armed)) {
      VibrationService.lightImpact();
    } else if (change.didChange(to: IndicatorState.loading)) {
      _bounceController.repeat(reverse: true);
    } else if (change.didChange(to: IndicatorState.complete)) {
      VibrationService.lightImpact();
      _bounceController.stop();
      _bounceController.value = 0.0;
    } else if (change.didChange(to: IndicatorState.idle) ||
        change.didChange(to: IndicatorState.canceling)) {
      _bounceController.stop();
      _bounceController.value = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      controller: widget.controller,
      offsetToArmed: widget.offsetToArmed,
      durations: const RefreshIndicatorDurations(
        completeDuration: Duration(milliseconds: 320),
        finalizeDuration: Duration(milliseconds: 180),
        settleDuration: Duration(milliseconds: 140),
      ),
      onStateChanged: _handleStateChanged,
      onRefresh: widget.onRefresh,
      builder: (context, child, controller) {
        return AnimatedBuilder(
          animation: Listenable.merge([controller, _bounceAnimation]),
          child: child,
          builder: (context, staticChild) {
            final double pullValue = controller.value.clamp(0.0, 1.4);
            final double headerHeight = pullValue * widget.offsetToArmed;
            final bool isArmed = controller.isArmed;
            final bool isLoading = controller.isLoading;
            final bool isComplete = controller.isComplete;

            // Mascot tilts playfully as user pulls down
            final double tiltAngle = (!isLoading && !isComplete)
                ? math.sin(pullValue.clamp(0.0, 1.0) * math.pi) * 0.12
                : 0.0;

            // Cheerful hopping translation when loading
            final double bounceOffset =
                isLoading ? -6.0 * _bounceAnimation.value : 0.0;

            // Dynamic scale of mascot badge
            final double scale = isArmed
                ? 1.06
                : (0.55 + 0.45 * pullValue.clamp(0.0, 1.0));

            // Status message and badge styling
            final String statusText;
            final Color textColor;
            final Color pillBgColor;
            final Color pillBorderColor;

            if (isComplete) {
              statusText = widget.completeText;
              textColor = AppColors.green;
              pillBgColor = AppColors.greenLight;
              pillBorderColor = AppColors.greenBorder;
            } else if (isLoading) {
              statusText = widget.loadingText;
              textColor = AppColors.primaryDark;
              pillBgColor = AppColors.surface;
              pillBorderColor = AppColors.primaryYellowDark;
            } else if (isArmed) {
              statusText = widget.armedText;
              textColor = AppColors.primaryDark;
              pillBgColor = AppColors.primaryYellow;
              pillBorderColor = AppColors.primaryYellowDark;
            } else {
              statusText = widget.draggingText;
              textColor = AppColors.textSecondary;
              pillBgColor = AppColors.surfaceVariant;
              pillBorderColor = AppColors.border;
            }

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Top Mascot Header Area (only rendered during pull gesture)
                if (headerHeight > 0.0)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: headerHeight,
                    child: ClipRect(
                      child: OverflowBox(
                        minHeight: 0.0,
                        maxHeight: widget.offsetToArmed,
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          height: widget.offsetToArmed,
                          child: Center(
                            child: Opacity(
                              opacity: pullValue.clamp(0.0, 1.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Mascot Badge with subtle ring loader during loading
                                  SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (isLoading)
                                          const SizedBox(
                                            width: 52,
                                            height: 52,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                AppColors.primaryYellow,
                                              ),
                                            ),
                                          ),
                                        Transform.translate(
                                          offset: Offset(0, bounceOffset),
                                          child: Transform.rotate(
                                            angle: tiltAngle,
                                            child: Transform.scale(
                                              scale: scale,
                                              child: Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppColors.surface,
                                                  border: Border.all(
                                                    color: isArmed || isLoading
                                                        ? AppColors.primaryYellow
                                                        : AppColors.borderSubtle,
                                                    width: 1.8,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors
                                                          .primaryDark
                                                          .withValues(
                                                              alpha: 0.1),
                                                      blurRadius: 8,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                clipBehavior: Clip.antiAlias,
                                                child: Image.asset(
                                                  'assets/logo-humora-rounded.png',
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Text Pill Badge
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: pillBgColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: pillBorderColor,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryDark
                                              .withValues(alpha: 0.04),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Content translates down
                Transform.translate(
                  offset: Offset(0.0, headerHeight),
                  child: staticChild ?? const SizedBox.shrink(),
                ),
              ],
            );
          },
        );
      },
      child: widget.child,
    );
  }
}
