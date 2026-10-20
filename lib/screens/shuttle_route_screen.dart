import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/campus_info.dart';
import '../data/sample_data.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/campus_palette.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';
import 'campus_map_screen.dart';

/// Details for one shuttle line: map of its stops, next departures and the
/// stop-by-stop timeline.
class ShuttleRouteScreen extends StatelessWidget {
  const ShuttleRouteScreen({super.key, required this.route});

  final ShuttleRoute route;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final departures = route.departuresAfter(now, count: 8);
    final stops = route.stops;

    return ValueListenableBuilder<Set<String>>(
      valueListenable: AppState.instance.shuttleAlerts,
      builder: (context, alerts, _) {
        final alertOn = alerts.contains(route.id);
        return GlassPage(
          title: route.name,
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(20),
              tint: 0.18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconBubble(icon: Icons.directions_bus_filled_rounded, size: 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(route.path, style: AppText.h3),
                            Text(route.frequency, style: AppText.caption),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(label: route.status, tone: route.tone),
                    ],
                  ),
                  const Divider(),
                  const Text('NEXT DEPARTURE', style: AppText.overline),
                  Text(
                    departures.isEmpty ? 'Tomorrow' : formatTime(departures.first),
                    style: AppText.display,
                  ),
                  Text(
                    departures.isEmpty
                        ? 'Service has ended for today. First bus ${formatTime(route.firstDeparture)}.'
                        : 'from ${stops.first.name}',
                    style: AppText.body,
                  ),
                ],
              ),
            ),
            const SectionHeader(title: 'Route map', icon: Icons.map_rounded),
            _RouteMap(stops: stops),
            const SectionHeader(title: 'Upcoming departures', icon: Icons.schedule_rounded),
            GlassContainer(
              child: departures.isEmpty
                  ? Text(
                      'No more departures today. Service starts at ${formatTime(route.firstDeparture)}.',
                      style: AppText.body,
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < departures.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: i == 0 ? context.selectedBg : context.faint,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: context.hairline),
                            ),
                            child: Text(
                              i == 0 ? 'Next · ${formatTime(departures[i])}' : formatTime(departures[i]),
                              style: TextStyle(
                                color: i == 0 ? context.selectedFg : context.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            const SectionHeader(title: 'Stops', icon: Icons.signpost_rounded),
            GlassContainer(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  for (var i = 0; i < stops.length; i++)
                    _StopRow(
                      index: i,
                      isLast: i == stops.length - 1,
                      name: stops[i].name,
                      detail: i == 0
                          ? 'Start'
                          : 'about ${i * route.minutesBetweenStops} min after departure',
                      icon: stops[i].icon,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PillButton(
              label: alertOn ? 'Alerts on for ${route.name}' : 'Alert me before it leaves',
              icon: alertOn ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              filled: !alertOn,
              expand: true,
              onPressed: () => runCampusAction<bool>(
                context,
                () => AppState.instance.toggleShuttleAlert(route.id),
                success: (on) => on
                    ? "We'll alert you 5 minutes before ${route.name} departs"
                    : 'Alerts turned off for ${route.name}',
              ),
            ),
            const SizedBox(height: 12),
            PillButton(
              label: 'Open campus map',
              icon: Icons.near_me_rounded,
              filled: false,
              expand: true,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.campusMap),
            ),
            const SizedBox(height: 12),
            const Text(
              'Stop locations are from OpenStreetMap. The timetable is sample data until a live shuttle feed is connected.',
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ],
        );
      },
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.stops});

  final List<CampusPlace> stops;

  @override
  Widget build(BuildContext context) {
    final points = <LatLng>[for (final s in stops) s.point];
    final palette = CampusPalette.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        height: 260,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(points),
              padding: const EdgeInsets.all(48),
              maxZoom: 18,
            ),
            backgroundColor: const Color(0xFF2A0505),
          ),
          children: [
            if (CampusMapScreen.showTiles)
              TileLayer(
                urlTemplate: palette.mapTiles,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'edu.scarletridge.crimson_campus',
                retinaMode: RetinaMode.isHighDensity(context),
              ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  strokeWidth: 6,
                  color: Colors.white,
                  borderStrokeWidth: 2,
                  borderColor: AppColors.primary,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < points.length; i++)
                  Marker(
                    point: points[i],
                    width: 30,
                    height: 30,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == 0 ? Colors.white : AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: i == 0 ? AppColors.primary : Colors.white, width: 2.5),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: i == 0 ? AppColors.primary : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.index,
    required this.isLast,
    required this.name,
    required this.detail,
    required this.icon,
  });

  final int index;
  final bool isLast;
  final String name;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == 0 ? context.selectedFg : context.selectedBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.isLight ? AppColors.primary : Colors.white, width: 2),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: index == 0 ? context.selectedBg : context.selectedFg,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 3, color: context.hairline),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.title),
                  Text(detail, style: AppText.caption),
                ],
              ),
            ),
          ),
          Icon(icon, color: context.accentInk, size: 20),
        ],
      ),
    );
  }
}
