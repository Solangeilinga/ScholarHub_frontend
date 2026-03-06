import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double radius;
  final bool isDarkBackground;
  final bool showLabel;
  final TextStyle? labelStyle;

  const AppLogo({
    super.key,
    this.size = 56,
    this.radius = 16,
    this.isDarkBackground = false,
    this.showLabel = false,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final asset = isDarkBackground
        ? 'assets/images/logo_white.png'
        : 'assets/images/logo.png';

    final fallbackBg =
        isDarkBackground ? Colors.white.withValues(alpha: 0.2) : AppTheme.primary;
    final fallbackIconColor =
        isDarkBackground ? Colors.white : Colors.white;

    final logoBox = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            color: fallbackBg,
            child: Icon(
              Icons.school_rounded,
              color: fallbackIconColor,
              size: size * 0.57,
            ),
          ),
        ),
      ),
    );

    if (!showLabel) return logoBox;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoBox,
        const SizedBox(height: 12),
        Text(
          'ScholarHub',
          style: labelStyle ??
              Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isDarkBackground ? Colors.white : AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
        ),
      ],
    );
  }
}
