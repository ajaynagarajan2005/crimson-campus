import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';

class ShuttleScreen extends StatelessWidget {
  const ShuttleScreen({super.key});

  void _toggleAlert(BuildContext context, ShuttleRoute route) {
    runCampusAction<bool>(
      context,
      () => AppState.instance.toggleShuttleAlert(route.id),
      success: (enabled) => enabled
          ? "We'll alert you 5 minutes before ${route.name} departs"
          : 'Alerts turned off for ${route.name}',
      icon: (enabled) =>
          enabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: AppState.instance.shuttleAlerts,
      builder: (context, alerts, _) => _page(context, alerts),
    );
  }

  Widget _page(BuildContext context, Set<String> alerts) {
    final next = shuttleRoutes.first;
    return GlassPage(
      title: 'Campus shuttle',
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(20),
          tint: 0.18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const StatusBadge(label: 'Live now', tone: BadgeTone.success),
                  const Spacer(),
                  Text(next.name, style: AppText.title),
                ],
              ),
              const SizedBox(height: 14),
              const Text('NEXT DEPARTURE', style: AppText.overline),
              Text(next.nextDeparture, style: AppText.display),
              Text('${next.path} · from ${next.stops.first.name}', style: AppText.body),
              const SizedBox(height: 16),
              _StopsTimeline(stops: [for (final stop in next.stops) stop.name]),
              const SizedBox(height: 14),
              PillButton(
                label: 'View ${next.name} details',
                icon: Icons.route_rounded,
                expand: true,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.shuttleRoute, arguments: next),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'All routes', icon: Icons.alt_route_rounded),
        for (final route in shuttleRoutes)
          GlassContainer(
            margin: const EdgeInsets.only(bottom: 10),
            onTap: () => Navigator.pushNamed(context, AppRoutes.shuttleRoute, arguments: route),
            semanticLabel: '${route.name}, ${route.status}. Opens route details',
            child: Row(
              children: [
                const IconBubble(icon: Icons.directions_bus_filled_rounded, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(route.name, style: AppText.title),
                          StatusBadge(label: route.status, tone: route.tone, dense: true),
                        ],
                      ),
                      Text(route.path, style: AppText.body),
                      Text('${route.frequency} · next ${route.nextDeparture}', style: AppText.caption),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: alerts.contains(route.id) ? 'Turn off alerts' : 'Alert me before it leaves',
                  color: context.accentInk,
                  icon: Icon(
                    alerts.contains(route.id)
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                  ),
                  onPressed: () => _toggleAlert(context, route),
                ),
                Icon(Icons.chevron_right_rounded, color: context.accentInk),
              ],
            ),
          ),
      ],
    );
  }
}

/// Horizontal stop indicator built from Containers.
class _StopsTimeline extends StatelessWidget {
  const _StopsTimeline({required this.stops});

  final List<String> stops;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stops.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i == 0 ? Colors.transparent : context.hairline,
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0 ? context.selectedBg : (context.isLight ? Colors.white : AppColors.primary),
                        border: Border.all(color: context.isLight ? AppColors.primary : Colors.white, width: 2.5),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i == stops.length - 1
                            ? Colors.transparent
                            : context.hairline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  stops[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
