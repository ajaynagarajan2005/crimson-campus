import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';
import 'glass_container.dart';

/// Reusable quick-access tile for a campus service.
class CampusActionCard extends StatelessWidget {
  const CampusActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.width,
    this.badge,
    this.badgeTone = BadgeTone.light,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double? width;
  final String? badge;
  final BadgeTone badgeTone;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: width,
      height: 104,
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
      borderRadius: AppRadius.tile,
      onTap: onTap,
      semanticLabel: 'Open $label',
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconBubble(icon: icon, size: 44),
              const SizedBox(height: AppSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -2,
              child: StatusBadge(label: badge!, tone: badgeTone, dense: true),
            ),
        ],
      ),
    );
  }
}
