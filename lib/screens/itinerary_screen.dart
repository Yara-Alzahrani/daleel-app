import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/review_changes_sheet.dart';
import '../services/notification_service.dart';
import 'day_map_screen.dart';

class ItineraryScreen extends StatefulWidget {
  final String tripId;
  const ItineraryScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _itinerary;
  String _tripCity = '';
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  bool _isSaved = false;
  bool _isSaving = false;
  bool _isRegenerating = false;
  bool _isEditMode = false;
  int _itineraryVersion = 0;
  final List<Map<String, dynamic>> _selectedSlots = [];
  final List<Map<String, dynamic>> _selectedForDelete = [];
  StreamSubscription<DocumentSnapshot>? _tripSubscription;

  @override
  void initState() {
    super.initState();
    _listenToTrip();
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    if (!_isLoading && _error == null) _tabController.dispose();
    super.dispose();
  }

  void _listenToTrip() {
    _tripSubscription = FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final data = snapshot.data()!;
      final itineraryRaw = data['itinerary'];

      if (itineraryRaw == null) {
        setState(() {
          _isRegenerating = false;
          _isLoading = false;
          _error = 'Itinerary not generated yet. Please wait or try again.';
        });
        return;
      }

      final itinerary = itineraryRaw is String
          ? jsonDecode(itineraryRaw) as Map<String, dynamic>
          : itineraryRaw as Map<String, dynamic>;

      final city = data['city'] as String? ??
          (data['preferences'] as Map?)?['city'] as String? ??
          '';

      final days = itinerary['days'] as List? ?? [];
      final wasLoading = _isLoading;
      final wasRegenerating = _isRegenerating;
      final lengthChanged = !wasLoading && days.length != _tabController.length;

      setState(() {
        _itinerary = itinerary;
        _tripCity = city;
        _isSaved = data['saved'] == true;
        _isLoading = false;
        _isRegenerating = false;
        _isEditMode = false;
        _error = null;
        _selectedSlots.clear();
        _selectedForDelete.clear();
        _itineraryVersion++;
        if (wasLoading || lengthChanged) {
          if (!wasLoading) _tabController.dispose();
          _tabController = TabController(length: days.length, vsync: this);
        }
      });

      if (wasRegenerating && mounted)
        _showSnackBar('Your plan has been updated!');
    }, onError: (e) {
      setState(() {
        _error = 'Failed to load itinerary: $e';
        _isLoading = false;
      });
    });
  }

  void _toggleSlot(
      int dayNumber, String period, String timeRange, String name) {
    setState(() {
      final match = (s) =>
          s['dayNumber'] == dayNumber &&
          s['period'] == period &&
          s['timeRange'] == timeRange;
      if (_selectedSlots.any(match)) {
        _selectedSlots.removeWhere(match);
      } else {
        _selectedForDelete.removeWhere(match);
        _selectedSlots.add({
          'dayNumber': dayNumber,
          'period': period,
          'timeRange': timeRange,
          'name': name
        });
      }
    });
  }

  void _toggleDelete(
      int dayNumber, String period, String timeRange, String name) {
    setState(() {
      final match = (s) =>
          s['dayNumber'] == dayNumber &&
          s['period'] == period &&
          s['timeRange'] == timeRange;
      if (_selectedForDelete.any(match)) {
        _selectedForDelete.removeWhere(match);
      } else {
        _selectedSlots.removeWhere(match);
        _selectedForDelete.add({
          'dayNumber': dayNumber,
          'period': period,
          'timeRange': timeRange,
          'name': name
        });
      }
    });
  }

  String _normalizeCity(String city) {
    switch (city.toLowerCase().trim().replaceAll('-', '').replaceAll(' ', '')) {
      case 'alula':
        return 'AlUla';
      case 'jeddah':
      case 'jiddah':
        return 'Jeddah';
      case 'riyadh':
        return 'Riyadh';
      case 'makkah':
      case 'mecca':
        return 'Makkah';
      default:
        return city.trim();
    }
  }

  String _normalizeType(String type) {
    switch (type.toLowerCase().trim()) {
      case 'meal':
      case 'food':
      case 'dining':
        return 'restaurant';
      default:
        return type.toLowerCase().trim();
    }
  }

  String? _venueField(Map<String, dynamic> data, String key) {
    if (data.containsKey(key)) return data[key]?.toString();
    final lower = key.toLowerCase();
    for (final k in data.keys) {
      if (k.toLowerCase() == lower) return data[k]?.toString();
    }
    return null;
  }

  Future<void> _onConfirmRegenerate() async {
    setState(() => _isRegenerating = true);
    await _tripSubscription?.cancel();
    _tripSubscription = null;

    try {
      final copy = jsonDecode(jsonEncode(_itinerary!)) as Map<String, dynamic>;
      final days = (copy['days'] as List)
          .map((d) => Map<String, dynamic>.from(d as Map))
          .toList();

      final city = _normalizeCity(_tripCity);

      final used = days
          .expand((d) => (d['slots'] as List? ?? []))
          .map((s) => ((s as Map)['name'] as String? ?? '').toLowerCase())
          .toSet();

      for (final s in _selectedForDelete) {
        final day = days.firstWhere((d) => d['dayNumber'] == s['dayNumber'],
            orElse: () => {});
        if (day.isEmpty) continue;
        (day['slots'] as List).removeWhere((slot) =>
            (slot as Map)['period'] == s['period'] &&
            slot['timeRange'] == s['timeRange']);
      }

      for (final s in _selectedSlots) {
        final day = days.firstWhere((d) => d['dayNumber'] == s['dayNumber'],
            orElse: () => {});
        if (day.isEmpty) continue;

        final slots = day['slots'] as List;
        final idx = slots.indexWhere((slot) =>
            (slot as Map)['period'] == s['period'] &&
            slot['timeRange'] == s['timeRange']);
        if (idx == -1) continue;

        final current = Map<String, dynamic>.from(slots[idx] as Map);
        final type = _normalizeType(current['type'] as String? ?? 'activity');

        final snap =
            await FirebaseFirestore.instance.collection('venues').get();

        final options = snap.docs.where((doc) {
          final v = doc.data();
          final vCity = _normalizeCity(_venueField(v, 'city') ?? '');
          final vType = _normalizeType(_venueField(v, 'venueType') ?? '');
          final vName = (_venueField(v, 'name') ?? '').toLowerCase().trim();
          return vCity == city && vType == type && !used.contains(vName);
        }).toList();

        if (options.isEmpty) continue;

        options.shuffle();
        final venue = options.first.data();
        final newName =
            _venueField(venue, 'name') ?? (current['name'] as String? ?? '');

        slots[idx] = {
          ...current,
          'name': newName,
          'description':
              _venueField(venue, 'description') ?? current['description'] ?? '',
          'location': {
            'name': newName,
            'area': city,
            'mapsQuery': _venueField(venue, 'mapsLink') ?? '$newName, $city',
          },
          'tips': [],
        };
        used.add(newName.toLowerCase());
      }

      copy['days'] = days;
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update({
        'itinerary': jsonEncode(copy),
        'updatedAt': FieldValue.serverTimestamp()
      });

      if (!mounted) return;
      setState(() {
        _isRegenerating = false;
        _isEditMode = false;
        _selectedSlots.clear();
        _selectedForDelete.clear();
        _itineraryVersion++;
      });
      _showSnackBar('Your plan has been updated!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRegenerating = false);
      _showSnackBar('Failed to update: $e', isError: true);
    } finally {
      _listenToTrip();
    }
  }

  Future<void> _savePlan() async {
    setState(() => _isSaving = true);
    try {
      final days = _itinerary!['days'] as List;
      await NotificationService.scheduleAndSaveTrip(
        tripId: widget.tripId,
        days: days,
        city: _tripCity,
      );
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update({'saved': true});
      setState(() => _isSaved = true);
      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (e) {
      _showSnackBar('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ✅ التعديل الوحيد: إصلاح فتح Google Maps
  Future<void> _showVenueDetails(String venueName) async {
    Map<String, dynamic>? venue;
    try {
      final snap = await FirebaseFirestore.instance.collection('venues').get();
      for (final doc in snap.docs) {
        if ((_venueField(doc.data(), 'name') ?? '').toLowerCase() ==
            venueName.toLowerCase()) {
          venue = doc.data();
          break;
        }
      }
    } catch (_) {}

    if (!mounted) return;

    final name =
        venue != null ? (_venueField(venue, 'name') ?? venueName) : venueName;
    final desc = venue != null ? (_venueField(venue, 'description') ?? '') : '';
    final city = venue != null ? (_venueField(venue, 'city') ?? '') : '';
    final type = venue != null
        ? (_venueField(venue, 'Type') ?? _venueField(venue, 'type') ?? '')
        : '';
    final maps = venue != null ? (_venueField(venue, 'mapsLink') ?? '') : '';
    final rate = (venue?['Rate'] ?? venue?['rate'])?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              )),
              Text(name,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 8),
              if (rate != null) ...[
                Row(children: [
                  const Icon(Icons.star, color: Color(0xFFFFB800), size: 18),
                  const SizedBox(width: 4),
                  Text(rate,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Text('/ 5',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ]),
                const SizedBox(height: 12),
              ],
              Wrap(spacing: 8, children: [
                if (type.isNotEmpty)
                  Chip(
                    label: Text(type,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF006E51))),
                    backgroundColor: const Color(0xFF006E51).withOpacity(0.1),
                    padding: EdgeInsets.zero,
                  ),
                if (city.isNotEmpty)
                  Chip(
                    label: Text(city,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[700])),
                    backgroundColor: Colors.grey[100],
                    padding: EdgeInsets.zero,
                  ),
              ]),
              const SizedBox(height: 16),
              if (desc.isNotEmpty) ...[
                const Text('About',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(desc,
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[700], height: 1.5)),
                const SizedBox(height: 20),
              ],
              // ✅ زر Google Maps مع fallback
              if (maps.isNotEmpty)
                GestureDetector(
                  onTap: () async {
                    // أولاً: جرب geo: عشان يفتح تطبيق الخرائط مباشرة
                    final geoUri =
                        Uri.parse('geo:0,0?q=${Uri.encodeComponent(name)}');
                    final mapsUri = Uri.parse(maps);
                    try {
                      await launchUrl(geoUri,
                          mode: LaunchMode.externalApplication);
                    } catch (_) {
                      try {
                        await launchUrl(mapsUri,
                            mode: LaunchMode.externalApplication);
                      } catch (_) {
                        await launchUrl(mapsUri,
                            mode: LaunchMode.platformDefault);
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                        color: const Color(0xFF006E51),
                        borderRadius: BorderRadius.circular(25)),
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Open in Google Maps',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Flexible(
            child:
                Text(msg, style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: isError ? Colors.red : const Color(0xFF006E51),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  double _calculateExpandedHeight(
      String title, String summary, Map<String, dynamic>? totalCost) {
    double h = 180;
    if (title.length > 40) h += 24;
    if (title.length > 80) h += 24;
    if (summary.length > 80) h += 20;
    if (summary.length > 160) h += 20;
    if (summary.length > 240) h += 20;
    if (totalCost != null) h += 44;
    return h;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFF006E51))));

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: const Color(0xFF006E51),
            foregroundColor: Colors.white,
            title: const Text('Itinerary')),
        body: Center(
            child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }

    final days = _itinerary!['days'] as List;
    final title = _itinerary!['title'] as String? ?? 'Your Itinerary';
    final summary = _itinerary!['summary'] as String? ?? '';
    final totalCost =
        _itinerary!['totalEstimatedCost'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRegenerating)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Color(0xFF006E51), strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Updating your plan...',
                        style: TextStyle(color: Color(0xFF006E51))),
                  ],
                ),
              )
            else if (_isSaved)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF006E51), size: 20),
                  SizedBox(width: 8),
                  Text('Trip saved',
                      style: TextStyle(
                          color: Color(0xFF006E51),
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                ],
              )
            else ...[
              if (!_isEditMode) ...[
                GestureDetector(
                  onTap: _isSaving ? null : _savePlan,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF006E51), Color(0xFFA384DA)]),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF006E51).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Center(
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    Icon(Icons.rocket_launch_outlined,
                                        color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text('Start This Trip',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                  ])),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              GestureDetector(
                onTap: () {
                  if (!_isEditMode) {
                    setState(() => _isEditMode = true);
                  } else if (_selectedSlots.isNotEmpty ||
                      _selectedForDelete.isNotEmpty) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24))),
                      builder: (_) => ReviewChangesSheet(
                        selectedSlots: List.from(_selectedSlots),
                        selectedForDelete: List.from(_selectedForDelete),
                        onConfirm: _onConfirmRegenerate,
                      ),
                    );
                  } else {
                    setState(() => _isEditMode = false);
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (_isEditMode &&
                            (_selectedSlots.isNotEmpty ||
                                _selectedForDelete.isNotEmpty))
                        ? const Color(0xFF006E51).withOpacity(0.15)
                        : const Color(0xFF006E51).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                      child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        !_isEditMode
                            ? Icons.edit_outlined
                            : (_selectedSlots.isNotEmpty ||
                                    _selectedForDelete.isNotEmpty)
                                ? Icons.check_circle_outline
                                : Icons.close,
                        color: const Color(0xFF006E51),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        !_isEditMode
                            ? 'Edit Plan'
                            : (_selectedSlots.isNotEmpty ||
                                    _selectedForDelete.isNotEmpty)
                                ? 'Update (${_selectedSlots.length + _selectedForDelete.length})'
                                : 'Cancel',
                        style: const TextStyle(
                            color: Color(0xFF006E51),
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  )),
                ),
              ),
            ],
          ],
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: _calculateExpandedHeight(title, summary, totalCost),
            pinned: true,
            backgroundColor: const Color(0xFF006E51),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF006E51), Color(0xFFA384DA)]),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 48, 16, 56),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(summary,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85))),
                        if (totalCost != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFE381).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              'Est. ${totalCost['amount']} ${totalCost['currency']}  •  ${totalCost['note'] ?? ''}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFFFFE381),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: List.generate(days.length, (i) {
                final day = days[i] as Map<String, dynamic>;
                return Tab(text: 'Day ${day['dayNumber']}');
              }),
            ),
          ),
        ],
        body: TabBarView(
          key: ValueKey(_itineraryVersion),
          controller: _tabController,
          children:
              days.map((d) => _buildDayTab(d as Map<String, dynamic>)).toList(),
        ),
      ),
    );
  }

  Widget _buildDayTab(Map<String, dynamic> day) {
    final slots = day['slots'] as List? ?? [];
    final theme = day['theme'] as String? ?? '';
    final date = day['date'] as String? ?? '';
    final dayNumber = day['dayNumber'] as int? ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFF006E51).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, color: Color(0xFF006E51)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(theme,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF006E51))),
                  Text(date,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              )),
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DayMapScreen(
                          dayNumber: dayNumber,
                          dayTheme: theme,
                          date: date,
                          slots: slots
                              .map((s) => s as Map<String, dynamic>)
                              .toList()),
                    )),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFF006E51),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.map_outlined, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Map',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...slots
            .map((s) => _buildSlotCard(s as Map<String, dynamic>, dayNumber))
            .toList(),
      ],
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot, int dayNumber) {
    final type = slot['type'] as String? ?? 'activity';
    final period = slot['period'] as String? ?? '';
    final name = slot['name'] as String? ?? '';
    final description = slot['description'] as String? ?? '';
    final timeRange = slot['timeRange'] as String? ?? '';
    final duration = slot['duration'] as String? ?? '';
    final location = slot['location'] as Map<String, dynamic>?;
    final cost = slot['estimatedCost'] as Map<String, dynamic>?;
    final tips = slot['tips'] as List? ?? [];
    final color = _slotColor(type);

    final isSelected = _selectedSlots.any((s) =>
        s['dayNumber'] == dayNumber &&
        s['period'] == period &&
        s['timeRange'] == timeRange);
    final isDeleteSelected = _selectedForDelete.any((s) =>
        s['dayNumber'] == dayNumber &&
        s['period'] == period &&
        s['timeRange'] == timeRange);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDeleteSelected
              ? Colors.red.withOpacity(0.5)
              : isSelected
                  ? const Color(0xFFA384DA)
                  : color.withOpacity(0.3),
          width: (isSelected || isDeleteSelected) ? 2 : 1,
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDeleteSelected
                  ? Colors.red.withOpacity(0.08)
                  : color.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_periodIcon(period), size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                    child: Text('$period  •  $timeRange',
                        style: TextStyle(
                            fontSize: 13,
                            color: color,
                            fontWeight: FontWeight.w500))),
                Icon(_slotIcon(type), size: 16, color: color),
                const SizedBox(width: 4),
                Text(type, style: TextStyle(fontSize: 12, color: color)),
                if (!_isSaved && _isEditMode) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        _toggleSlot(dayNumber, period, timeRange, name),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFA384DA).withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                          isSelected ? Icons.check_circle : Icons.edit_outlined,
                          size: 16,
                          color: isSelected ? const Color(0xFFA384DA) : color),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () =>
                        _toggleDelete(dayNumber, period, timeRange, name),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDeleteSelected
                            ? Colors.red.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                          isDeleteSelected
                              ? Icons.delete
                              : Icons.delete_outline,
                          size: 16,
                          color: isDeleteSelected ? Colors.red : Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 6),
                Text(description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                if (location != null) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Color(0xFF006E51)),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text('${location['name']}, ${location['area']}',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF006E51)))),
                  ]),
                ],
                const SizedBox(height: 8),
                Row(children: [
                  if (duration.isNotEmpty) ...[
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(duration,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(width: 16),
                  ],
                  if (cost != null) ...[
                    const Icon(Icons.attach_money,
                        size: 14, color: Colors.grey),
                    Flexible(
                        child: Text(
                      cost['amount'] == 0
                          ? 'Free'
                          : '${cost['amount']} ${cost['currency']}${cost['perPerson'] == true ? '/person' : ''}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    )),
                  ],
                ]),
                if (tips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Tips',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA384DA))),
                  const SizedBox(height: 4),
                  ...tips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(color: Color(0xFFA384DA))),
                              Expanded(
                                  child: Text(tip.toString(),
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700]))),
                            ]),
                      )),
                ],
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showVenueDetails(name),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFF006E51).withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                        child: Text('View More',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF006E51),
                                fontWeight: FontWeight.w500))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _slotColor(String type) {
    switch (type) {
      case 'restaurant':
      case 'meal':
        return const Color(0xFFE67E22);
      case 'transport':
        return const Color(0xFF2980B9);
      default:
        return const Color(0xFF006E51);
    }
  }

  IconData _slotIcon(String type) {
    switch (type) {
      case 'restaurant':
      case 'meal':
        return Icons.restaurant_outlined;
      case 'transport':
        return Icons.directions_car_outlined;
      default:
        return Icons.explore_outlined;
    }
  }

  IconData _periodIcon(String period) {
    switch (period) {
      case 'afternoon':
        return Icons.wb_cloudy_outlined;
      case 'evening':
        return Icons.nights_stay_outlined;
      default:
        return Icons.wb_sunny_outlined;
    }
  }
}
