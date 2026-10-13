import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small rounded label such as "Due soon", "New" or "Registered".
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.light,
    this.dense = false,
  });

  final String label;
  final BadgeTone tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      BadgeTone.success => (AppColors.success, const Color(0xFF0B4D2C)),
      BadgeTone.warning => (AppColors.warning, const Color(0xFF5A3B00)),
      BadgeTone.danger => (Colors.white, AppColors.primary),
      BadgeTone.info => (AppColors.tintBlush, AppColors.primaryDark),
      BadgeTone.light => Theme.of(context).brightness == Brightness.light
          ? (AppColors.primary.withValues(alpha: 0.10), AppColors.primaryDark)
          : (Colors.white.withValues(alpha: 0.20), Colors.white),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 10,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: dense ? 10.5 : 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Section title with an optional "See all" style action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
        left: AppSpacing.xs,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Semantics(header: true, child: Text(title, style: AppText.h3)),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded white square holding a red icon — the app's icon style.
class IconBubble extends StatelessWidget {
  const IconBubble({
    super.key,
    required this.icon,
    this.size = 44,
    this.background = Colors.white,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final double size;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: size * 0.52),
    );
  }
}

/// Pill-shaped button. Filled = white with red text, outlined = glass.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    // Dark theme: white button on red. Light theme: red button on white.
    final light = Theme.of(context).brightness == Brightness.light;
    final face = light ? AppColors.primary : Colors.white;
    final onFace = light ? Colors.white : AppColors.primary;
    final foreground = filled ? onFace : face;
    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            color: filled ? face : (light ? Colors.white.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: face.withValues(alpha: filled ? 1 : 0.5),
            ),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: onPressed,
            customBorder: const StadiumBorder(),
            splashColor: AppColors.accent.withValues(alpha: 0.25),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: foreground, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded progress bar built from two Containers.
class GlassProgressBar extends StatelessWidget {
  const GlassProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color = Colors.white,
  });

  final double value;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Semantics(
      value: '${(clamped * 100).round()} percent',
      child: Container(
        height: height,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(height),
        ),
        child: FractionallySizedBox(
          widthFactor: clamped,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon + label + value row used on detail cards.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          IconBubble(
            icon: icon,
            size: 36,
            background: Colors.white.withValues(alpha: 0.18),
            iconColor: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.caption),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// White calendar tile showing a day number and month.
class DateTile extends StatelessWidget {
  const DateTile({super.key, required this.day, required this.month});

  final String day;
  final String month;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 70,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          Text(
            month,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small icon + text line used for time / venue details.
class MetaLine extends StatelessWidget {
  const MetaLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: AppText.caption)),
        ],
      ),
    );
  }
}

/// Runs a backend call and reports the outcome in a SnackBar.
/// Returns the result, or null if it failed (the error is already shown).
Future<T?> runCampusAction<T>(
  BuildContext context,
  Future<T> Function() action, {
  String Function(T result)? success,
  IconData Function(T result)? icon,
}) async {
  try {
    final result = await action();
    if (success != null && context.mounted) {
      showCampusSnack(
        context,
        success(result),
        icon: icon?.call(result) ?? Icons.check_circle_rounded,
      );
    }
    return result;
  } catch (error) {
    if (context.mounted) {
      showCampusSnack(context, error.toString(), icon: Icons.error_outline_rounded);
    }
    return null;
  }
}

/// Consistent white floating SnackBar used for tap feedback.
void showCampusSnack(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_rounded,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 2),
      content: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}
