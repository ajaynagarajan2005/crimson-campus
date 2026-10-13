import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/campus_info.dart';
import '../services/browser.dart';
import '../services/campus_api.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/campus_palette.dart';
import '../widgets/campus_themed.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';

/// Live campus map: building pins, your real-time position and walking
/// directions (straight-line distance and heading, plus Google Maps hand-off).
class CampusMapScreen extends StatelessWidget {
  const CampusMapScreen({super.key});

  /// Tests have no network, so they turn map tiles off.
  static bool showTiles = true;

  @override
  Widget build(BuildContext context) => const CampusThemed(child: _CampusMap());
}

class _CampusMap extends StatefulWidget {
  const _CampusMap();

  @override
  State<_CampusMap> createState() => _CampusMapState();
}

class _CampusMapState extends State<_CampusMap> {
  static const _distance = Distance();
  static const _farAway = 3000.0; // metres from campus centre

  final _map = MapController();
  bool _mapReady = false;

  CampusPlace? _selected = campusPlaces.first;
  bool _showRoute = false;

  /// Walking path from the routing service, or null for a straight line.
  List<LatLng>? _path;
  String? _routeNote;

  LatLng? _me;
  double? _accuracy;
  bool _tracking = false;
  bool _simulated = false;
  String? _error;
  int? _watchId;

  @override
  void dispose() {
    _stopWatch();
    super.dispose();
  }

  void _stopWatch() {
    final id = _watchId;
    if (id != null) Browser.stopWatching(id);
    _watchId = null;
  }

  void _toggleTracking() {
    if (_tracking) {
      _stopWatch();
      setState(() => _tracking = false);
      return;
    }
    if (!Browser.supportsLocation) {
      setState(() => _error = 'Live location works in the web version of the app.');
      return;
    }
    setState(() {
      _tracking = true;
      _simulated = false;
      _error = null;
    });
    var first = true;
    _watchId = Browser.watchLocation(
      (fix) {
        if (!mounted) return;
        final me = LatLng(fix.lat, fix.lon);
        setState(() {
          _me = me;
          _accuracy = fix.accuracy;
          _error = null;
        });
        if (first && _mapReady && !_isFar) _map.move(me, 18);
        first = false;
      },
      (message) {
        if (!mounted) return;
        setState(() {
          _error = message;
          _tracking = false;
        });
      },
    );
  }

  /// Puts a demo "you are here" at the north entrance, for trying the
  /// directions when you are not on campus.
  void _simulate() {
    _stopWatch();
    final gate = campusPlaces.firstWhere((p) => p.id == 'north-gate').point;
    setState(() {
      _me = gate;
      _accuracy = 8;
      _tracking = false;
      _simulated = true;
      _error = null;
    });
    if (_mapReady) _map.move(gate, 17.5);
  }

  void _select(CampusPlace place) {
    setState(() {
      _selected = place;
      _showRoute = false;
      _path = null;
      _routeNote = null;
    });
    if (_mapReady) _map.move(place.point, 18);
  }

  Future<void> _routeTo(CampusPlace place) async {
    setState(() {
      _showRoute = true;
      _path = null;
      _routeNote = null;
    });
    final me = _me;
    if (me != null && !_isFar) {
      // Ask the backend for a real walking path; fall back to a straight line.
      try {
        final route = await AppState.instance.api.walkingRoute(
          me.latitude,
          me.longitude,
          place.point.latitude,
          place.point.longitude,
        );
        if (!mounted || _selected != place) return;
        setState(() {
          _path = [for (final (lat, lon) in route.points) LatLng(lat, lon)];
          final minutes = route.durationSeconds == null ? null : (route.durationSeconds! / 60).ceil();
          _routeNote = minutes == null ? 'Walking path' : 'Walking path · about $minutes min';
        });
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() => _routeNote = e.statusCode == 503
            ? 'Straight-line guide (walking paths need a routing key on the server)'
            : 'Straight-line guide (walking path unavailable right now)');
      }
    }
    if (me != null && _mapReady && !_isFar) {
      _map.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(me, place.point),
          padding: const EdgeInsets.fromLTRB(48, 170, 48, 330),
          maxZoom: 18.5,
        ),
      );
    }
  }

  void _openGoogleMaps(CampusPlace place) {
    final p = place.point;
    Browser.openInNewTab(
      'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}&travelmode=walking',
    );
  }

  bool get _isFar => _me != null && _distance.as(LengthUnit.Meter, _me!, campusCenter) > _farAway;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    final selected = _selected;
    final me = _me;

    return Scaffold(
      backgroundColor: palette.backdrop.first,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: campusCenter,
                initialZoom: 17,
                minZoom: 14,
                maxZoom: 19.5,
                backgroundColor: palette.isDark ? const Color(0xFF2A0505) : const Color(0xFFF7F1EE),
                onMapReady: () => _mapReady = true,
              ),
              children: [
                if (CampusMapScreen.showTiles)
                  TileLayer(
                    urlTemplate: palette.mapTiles,
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'edu.scarletridge.crimson_campus',
                    retinaMode: RetinaMode.isHighDensity(context),
                  ),
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: campusOutline,
                      color: AppColors.primary.withValues(alpha: palette.isDark ? 0.16 : 0.08),
                      borderColor: AppColors.primary.withValues(alpha: 0.7),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                if (_showRoute && me != null && selected != null && !_isFar)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _path ?? [me, selected.point],
                        strokeWidth: 6,
                        color: palette.isDark ? Colors.white : AppColors.primary,
                        borderStrokeWidth: 2,
                        borderColor: palette.isDark ? AppColors.primary : Colors.white,
                      ),
                    ],
                  ),
                if (me != null && _accuracy != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: me,
                        radius: _accuracy!.clamp(5, 200).toDouble(),
                        useRadiusInMeter: true,
                        color: const Color(0xFF1E88E5).withValues(alpha: 0.15),
                        borderColor: const Color(0xFF1E88E5).withValues(alpha: 0.5),
                        borderStrokeWidth: 1,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (final place in campusPlaces)
                      Marker(
                        point: place.point,
                        width: 52,
                        height: 52,
                        child: _PlacePin(
                          place: place,
                          selected: place == selected,
                          onTap: () => _select(place),
                        ),
                      ),
                    if (me != null)
                      Marker(point: me, width: 26, height: 26, child: const _MeDot()),
                  ],
                ),
              ],
            ),
          ),
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(palette: palette, tracking: _tracking, simulated: _simulated),
                    if (_error != null)
                      _Banner(
                        palette: palette,
                        icon: Icons.location_off_rounded,
                        message: _error!,
                        actionLabel: 'Try demo position',
                        onAction: _simulate,
                      )
                    else if (_isFar)
                      _Banner(
                        palette: palette,
                        icon: Icons.travel_explore_rounded,
                        message:
                            'You are ${_formatDistance(_distance.as(LengthUnit.Meter, me!, campusCenter))} from campus. '
                            'Live directions start once you are there.',
                        actionLabel: 'Try demo position',
                        onAction: _simulate,
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Map controls
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapButton(
                    palette: palette,
                    icon: _tracking ? Icons.my_location_rounded : Icons.location_searching_rounded,
                    tooltip: _tracking ? 'Stop live location' : 'Show my live location',
                    active: _tracking,
                    onTap: _toggleTracking,
                  ),
                  const SizedBox(height: 10),
                  _MapButton(
                    palette: palette,
                    icon: Icons.center_focus_strong_rounded,
                    tooltip: 'Back to campus',
                    onTap: () {
                      if (_mapReady) _map.move(campusCenter, 17);
                    },
                  ),
                  const SizedBox(height: 10),
                  _MapButton(
                    palette: palette,
                    icon: Icons.add_rounded,
                    tooltip: 'Zoom in',
                    onTap: () {
                      if (_mapReady) _map.move(_map.camera.center, _map.camera.zoom + 1);
                    },
                  ),
                  const SizedBox(height: 10),
                  _MapButton(
                    palette: palette,
                    icon: Icons.remove_rounded,
                    tooltip: 'Zoom out',
                    onTap: () {
                      if (_mapReady) _map.move(_map.camera.center, _map.camera.zoom - 1);
                    },
                  ),
                ],
              ),
            ),
          ),
          // Bottom sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: GlassContainer(
                      colors: palette.glassStrong,
                      borderColor: palette.glassBorder,
                      blur: 20,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (selected != null)
                            _PlaceDetails(
                              palette: palette,
                              place: selected,
                              me: me,
                              far: _isFar,
                              onRoute: me == null ? _toggleTracking : () => _routeTo(selected),
                              onGoogleMaps: () => _openGoogleMaps(selected),
                            ),
                          if (_showRoute && _routeNote != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _routeNote!,
                                style: AppText.caption.copyWith(color: palette.textMuted, fontStyle: FontStyle.italic),
                              ),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 44,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: campusPlaces.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (context, i) => _PlaceChip(
                                palette: palette,
                                place: campusPlaces[i],
                                selected: campusPlaces[i] == selected,
                                onTap: () => _select(campusPlaces[i]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Map data © OpenStreetMap contributors · tiles © CARTO',
                            textAlign: TextAlign.center,
                            style: AppText.caption.copyWith(color: palette.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDistance(double metres) {
  if (metres < 1000) return '${metres.round()} m';
  if (metres < 100000) return '${(metres / 1000).toStringAsFixed(1)} km';
  final km = (metres / 1000).round().toString();
  final grouped = km.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  return '$grouped km';
}

String _compass(double bearing) {
  const names = ['north', 'north-east', 'east', 'south-east', 'south', 'south-west', 'west', 'north-west'];
  final index = (((bearing % 360) + 360 + 22.5) % 360 ~/ 45).toInt();
  return names[index];
}

class _Header extends StatelessWidget {
  const _Header({required this.palette, required this.tracking, required this.simulated});

  final CampusPalette palette;
  final bool tracking;
  final bool simulated;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return GlassContainer(
      colors: palette.glassStrong,
      borderColor: palette.glassBorder,
      padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
      borderRadius: 26,
      child: Row(
        children: [
          if (canPop)
            IconButton(
              tooltip: 'Back',
              color: palette.text,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            )
          else
            const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Campus map', style: AppText.h3.copyWith(color: palette.text)),
                Text(
                  'INTI International University, Nilai',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(color: palette.textMuted),
                ),
              ],
            ),
          ),
          if (tracking || simulated)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: StatusBadge(
                label: simulated ? 'Demo' : 'Live',
                tone: simulated ? BadgeTone.warning : BadgeTone.success,
                dense: true,
              ),
            ),
          const ThemeToggleButton(),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.palette,
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final CampusPalette palette;
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(top: 8),
      colors: palette.glassStrong,
      borderColor: palette.glassBorder,
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      borderRadius: 20,
      child: Row(
        children: [
          Icon(icon, color: palette.isDark ? AppColors.warning : AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: AppText.caption.copyWith(color: palette.text)),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: palette.isDark ? Colors.white : AppColors.primary,
              minimumSize: const Size(48, 44),
            ),
            child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.palette,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final CampusPalette palette;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GlassContainer(
        width: 48,
        height: 48,
        padding: EdgeInsets.zero,
        borderRadius: 16,
        alignment: Alignment.center,
        colors: active ? [const Color(0xFF1E88E5), const Color(0xFF1565C0)] : palette.glassStrong,
        borderColor: palette.glassBorder,
        semanticLabel: tooltip,
        onTap: onTap,
        child: Icon(icon, color: active ? Colors.white : (palette.isDark ? Colors.white : AppColors.primary)),
      ),
    );
  }
}

class _PlacePin extends StatelessWidget {
  const _PlacePin({required this.place, required this.selected, required this.onTap});

  final CampusPlace place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    final size = selected ? 46.0 : 34.0;
    return Semantics(
      button: true,
      label: place.name,
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? palette.accent : (palette.isDark ? AppColors.primary : Colors.white),
              shape: BoxShape.circle,
              border: Border.all(
                color: palette.isDark ? Colors.white : AppColors.primary,
                width: selected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(
              place.icon,
              size: size * 0.5,
              color: selected
                  ? palette.onAccent
                  : (palette.isDark ? Colors.white : AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeDot extends StatelessWidget {
  const _MeDot();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your location',
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E88E5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1E88E5).withValues(alpha: 0.5), blurRadius: 12),
          ],
        ),
      ),
    );
  }
}

class _PlaceDetails extends StatelessWidget {
  const _PlaceDetails({
    required this.palette,
    required this.place,
    required this.me,
    required this.far,
    required this.onRoute,
    required this.onGoogleMaps,
  });

  static const _distance = Distance();

  final CampusPalette palette;
  final CampusPlace place;
  final LatLng? me;
  final bool far;
  final VoidCallback onRoute;
  final VoidCallback onGoogleMaps;

  @override
  Widget build(BuildContext context) {
    final from = me;
    String? guidance;
    double? bearing;
    if (from != null) {
      final metres = _distance.as(LengthUnit.Meter, from, place.point);
      bearing = _distance.bearing(from, place.point);
      final minutes = (metres / 80).ceil();
      guidance = far
          ? '${_formatDistance(metres)} away'
          : '${_formatDistance(metres)} · about $minutes min walk · head ${_compass(bearing)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconBubble(
              icon: place.icon,
              size: 44,
              background: palette.isDark ? Colors.white : AppColors.primary,
              iconColor: palette.isDark ? AppColors.primary : Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: AppText.title.copyWith(color: palette.text)),
                  Text(place.description, style: AppText.caption.copyWith(color: palette.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(label: place.category, tone: BadgeTone.info, dense: true),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Transform.rotate(
              angle: (bearing ?? 0) * 3.1415926535 / 180,
              child: Icon(
                from == null ? Icons.location_disabled_rounded : Icons.navigation_rounded,
                size: 20,
                color: palette.isDark ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                guidance ?? 'Turn on live location for walking directions.',
                style: AppText.caption.copyWith(color: palette.text, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: from == null ? 'Start live location' : 'Show route',
                icon: from == null ? Icons.my_location_rounded : Icons.alt_route_rounded,
                expand: true,
                onPressed: onRoute,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                label: 'Maps',
                icon: Icons.open_in_new_rounded,
                filled: false,
                expand: true,
                onPressed: onGoogleMaps,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip({
    required this.palette,
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final CampusPalette palette;
  final CampusPlace place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? palette.onAccent : palette.text;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.accent : palette.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(place.icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(place.name, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
