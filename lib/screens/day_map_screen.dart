import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class DayMapScreen extends StatefulWidget {
  final int dayNumber;
  final String dayTheme;
  final String date;
  final List<Map<String, dynamic>> slots;

  const DayMapScreen({
    Key? key,
    required this.dayNumber,
    required this.dayTheme,
    required this.date,
    required this.slots,
  }) : super(key: key);

  @override
  State<DayMapScreen> createState() => _DayMapScreenState();
}

class _DayMapScreenState extends State<DayMapScreen> {
  List<_MapLocation> _locations = [];
  bool _isLoading = true;
  String? _geocodeError;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final List<_MapLocation> resolved = [];

    for (final slot in widget.slots) {
      final type = slot['type'] as String? ?? 'activity';
      // skip transport slots — they don't add map pins
      if (type == 'transport') continue;

      final location = slot['location'] as Map<String, dynamic>?;
      if (location == null) continue;

      final locName = location['name'] as String? ?? '';
      final area = location['area'] as String? ?? '';
      final slotName = slot['name'] as String? ?? locName;
      final period = slot['period'] as String? ?? '';

      // prefer embedded coordinates if n8n provides them
      double? lat = (location['lat'] as num?)?.toDouble();
      double? lng = (location['lng'] as num?)?.toDouble();

      if (lat == null || lng == null) {
        final coords = await _geocodeWithFallback(locName, area);
        if (coords != null) {
          lat = coords.latitude;
          lng = coords.longitude;
        }
      }

      if (lat != null && lng != null) {
        resolved.add(_MapLocation(
          name: slotName,
          locationName: locName,
          area: area,
          latLng: LatLng(lat, lng),
          type: type,
          period: period,
        ));
      }
    }

    if (!mounted) return;
    setState(() {
      _locations = resolved;
      _isLoading = false;
      if (resolved.isEmpty) {
        _geocodeError = 'Could not resolve any locations on the map.';
      }
    });

    if (resolved.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  Future<LatLng?> _geocodeWithFallback(String locName, String area) async {
    // Try 1: venue + area + country (strict)
    final r1 = await _nominatim('$locName, $area, Saudi Arabia', countryCode: 'sa');
    if (r1 != null) return r1;

    // Try 2: venue + country only
    if (locName.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 600));
      final r2 = await _nominatim('$locName, Saudi Arabia', countryCode: 'sa');
      if (r2 != null) return r2;
    }

    // Try 3: venue + area, no country code restriction (some SA venues indexed without it)
    if (locName.isNotEmpty && area.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 600));
      final r3 = await _nominatim('$locName, $area');
      if (r3 != null) return r3;
    }

    // Try 4: venue name alone, no restriction
    if (locName.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 600));
      final r4 = await _nominatim(locName);
      if (r4 != null) return r4;
    }

    // Try 5: area only — at least pins the general neighbourhood
    if (area.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 600));
      final r5 = await _nominatim('$area, Saudi Arabia', countryCode: 'sa');
      if (r5 != null) return r5;
    }

    return null;
  }

  Future<LatLng?> _nominatim(String query, {String? countryCode = 'sa'}) async {
    try {
      final params = <String, String>{
        'q': query,
        'format': 'json',
        'limit': '1',
      };
      if (countryCode != null) params['countrycodes'] = countryCode;

      final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'DaleelApp/1.0 (travel planning)'},
      );
      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List;
        if (results.isNotEmpty) {
          return LatLng(
            double.parse(results[0]['lat'] as String),
            double.parse(results[0]['lon'] as String),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  void _fitBounds() {
    if (_locations.isEmpty) return;
    if (_locations.length == 1) {
      _mapController.move(_locations.first.latLng, 14);
      return;
    }
    final lats = _locations.map((l) => l.latLng.latitude);
    final lngs = _locations.map((l) => l.latLng.longitude);
    final bounds = LatLngBounds(
      LatLng(lats.reduce(min) - 0.01, lngs.reduce(min) - 0.01),
      LatLng(lats.reduce(max) + 0.01, lngs.reduce(max) + 0.01),
    );
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(56)),
    );
  }

  double _distanceKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLon = (b.longitude - a.longitude) * pi / 180;
    final sinLat = sin(dLat / 2);
    final sinLon = sin(dLon / 2);
    final x = sinLat * sinLat +
        sinLon * sinLon * cos(a.latitude * pi / 180) * cos(b.latitude * pi / 180);
    return r * 2 * atan2(sqrt(x), sqrt(1 - x));
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'restaurant':
        return const Color(0xFFE67E22);
      default:
        return const Color(0xFF006E51);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF006E51), Color(0xFFA384DA)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Day ${widget.dayNumber} — Map',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 17)),
            if (widget.dayTheme.isNotEmpty)
              Text(widget.dayTheme,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF006E51)),
                  const SizedBox(height: 16),
                  Text(
                    'Locating places on map…',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This may take a few seconds',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            )
          : _geocodeError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_off_outlined,
                            size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(_geocodeError!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 15)),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // ── Map ──────────────────────────────────────────────
                    Expanded(
                      flex: 3,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _locations.first.latLng,
                          initialZoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.daleel_app',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points:
                                    _locations.map((l) => l.latLng).toList(),
                                strokeWidth: 3.5,
                                color:
                                    const Color(0xFF006E51).withValues(alpha: 0.65),
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: _locations.asMap().entries.map((e) {
                              final i = e.key;
                              final loc = e.value;
                              return Marker(
                                point: loc.latLng,
                                width: 40,
                                height: 40,
                                child: _MapPin(
                                    number: i + 1,
                                    color: _typeColor(loc.type)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // ── Route list ───────────────────────────────────────
                    Expanded(
                      flex: 2,
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              color:
                                  const Color(0xFF006E51).withValues(alpha: 0.06),
                              child: Row(
                                children: [
                                  const Icon(Icons.route_outlined,
                                      color: Color(0xFF006E51), size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_locations.length} stops  •  ${widget.date}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Color(0xFF006E51)),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                itemCount: _locations.length,
                                itemBuilder: (ctx, i) {
                                  final loc = _locations[i];
                                  String? distText;
                                  if (i < _locations.length - 1) {
                                    final km = _distanceKm(
                                        loc.latLng, _locations[i + 1].latLng);
                                    distText = km < 1
                                        ? '${(km * 1000).round()} m'
                                        : '${km.toStringAsFixed(1)} km';
                                  }
                                  return _RouteItem(
                                    index: i + 1,
                                    loc: loc,
                                    distanceToNext: distText,
                                    color: _typeColor(loc.type),
                                    isLast: i == _locations.length - 1,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ── Pin widget ────────────────────────────────────────────────────────────────

class _MapPin extends StatelessWidget {
  final int number;
  final Color color;
  const _MapPin({required this.number, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Center(
        child: Text('$number',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ),
    );
  }
}

// ── Route list item ───────────────────────────────────────────────────────────

class _RouteItem extends StatelessWidget {
  final int index;
  final _MapLocation loc;
  final String? distanceToNext;
  final Color color;
  final bool isLast;

  const _RouteItem({
    required this.index,
    required this.loc,
    required this.distanceToNext,
    required this.color,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: number + connecting line
          SizedBox(
            width: 52,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ]),
                  child: Center(
                    child: Text('$index',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey[200],
                    ),
                  ),
              ],
            ),
          ),
          // Right: content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text('${loc.locationName}, ${loc.area}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                  if (distanceToNext != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.straight,
                          size: 13, color: Color(0xFF006E51)),
                      const SizedBox(width: 4),
                      Text('$distanceToNext to next stop',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF006E51),
                              fontWeight: FontWeight.w500)),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _MapLocation {
  final String name;
  final String locationName;
  final String area;
  final LatLng latLng;
  final String type;
  final String period;

  const _MapLocation({
    required this.name,
    required this.locationName,
    required this.area,
    required this.latLng,
    required this.type,
    required this.period,
  });
}
