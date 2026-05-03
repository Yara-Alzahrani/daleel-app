import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/review_changes_sheet.dart';
import 'day_map_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ItineraryScreen extends StatefulWidget {
  final String tripId;
  const ItineraryScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _itinerary;
  String? _tripCity;
  bool _isLoading = true;
  String? _error;
  TabController? _tabController;
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
        if (_isRegenerating) return;
        setState(() {
          _isLoading = false;
          _error = 'Itinerary not generated yet. Please wait or try again.';
        });
        return;
      }

      Map<String, dynamic> itinerary;
      try {
        itinerary = itineraryRaw is String
            ? Map<String, dynamic>.from(jsonDecode(itineraryRaw) as Map)
            : Map<String, dynamic>.from(itineraryRaw as Map);
      } catch (e) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to parse itinerary: $e';
        });
        return;
      }

      final city = data['city'] as String?
          ?? (data['preferences'] as Map?)?['city'] as String?
          ?? itinerary['city'] as String?
          ?? '';

      final days = itinerary['days'] as List? ?? [];
      final newLength = days.length;
      final wasRegenerating = _isRegenerating;
      final lengthChanged =
          _tabController == null || newLength != _tabController!.length;

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
        if (lengthChanged) {
          _tabController?.dispose();
          _tabController = TabController(length: newLength, vsync: this);
        }
      });

      if (wasRegenerating && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Your plan has been updated!',
                  style: TextStyle(fontWeight: FontWeight.w500)),
            ]),
            backgroundColor: const Color(0xFF006E51),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }, onError: (e) {
      setState(() {
        _error = 'Failed to load itinerary: $e';
        _isLoading = false;
      });
    });
  }

  void _toggleSlot(int dayNumber, String period, String name, String timeRange) {
    setState(() {
      final exists = _selectedSlots.any((s) =>
          s['dayNumber'] == dayNumber && s['period'] == period && s['timeRange'] == timeRange);
      if (exists) {
        _selectedSlots.removeWhere((s) =>
            s['dayNumber'] == dayNumber && s['period'] == period && s['timeRange'] == timeRange);
      } else {
        _selectedForDelete.removeWhere((s) =>
            s['dayNumber'] == dayNumber && s['period'] == period && s['timeRange'] == timeRange);
        _selectedSlots.add(
            {'dayNumber': dayNumber, 'period': period, 'timeRange': timeRange, 'name': name});
      }
    });
  }

  void _toggleDelete(int dayNumber, String period, String name, String timeRange) {
    setState(() {
      final exists = _selectedForDelete.any((s) =>
          s['dayNumber'] == dayNumber && s['period'] == period && s['timeRange'] == timeRange);
      if (exists) {
        _selectedForDelete.removeWhere((s) =>
            s['dayNumber'] == dayNumber && s['period'] == period && s['timeRange'] == timeRange);
      } else {
        _selectedSlots.removeWhere((s) =>
            s['dayNumber'] == dayNumber && s['period'] == period && s['timeRange'] == timeRange);
        _selectedForDelete.add(
            {'dayNumber': dayNumber, 'period': period, 'timeRange': timeRange, 'name': name});
      }
    });
  }

  void _showReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ReviewChangesSheet(
        selectedSlots: List.from(_selectedSlots),
        selectedForDelete: List.from(_selectedForDelete),
        onConfirm: _onConfirmRegenerate,
      ),
    );
  }

  String? _venueField(Map<String, dynamic> data, String key) {
    if (data.containsKey(key)) {
      final val = data[key];
      return val != null ? val.toString() : null;
    }
    final lower = key.toLowerCase();
    for (final k in data.keys) {
      if (k.toLowerCase() == lower) {
        final val = data[k];
        return val != null ? val.toString() : null;
      }
    }
    return null;
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> map) {
    return Map<String, dynamic>.from(jsonDecode(jsonEncode(map)) as Map);
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

  Future<void> _onConfirmRegenerate() async {
    setState(() => _isRegenerating = true);
    await _tripSubscription?.cancel();
    _tripSubscription = null;

    try {
      final city = _tripCity ?? '';
      final itineraryCopy = _deepCopy(_itinerary!);

      final updatedDays = (itineraryCopy['days'] as List)
          .map((d) => Map<String, dynamic>.from(d as Map))
          .toList();

      final usedNames = updatedDays
          .expand((d) => (d['slots'] as List? ?? []))
          .map((s) =>
              ((s as Map<String, dynamic>)['name'] as String? ?? '')
                  .toLowerCase())
          .toSet();

      // --- حذف ---
      for (final selected in _selectedForDelete) {
        final dayNumber = selected['dayNumber'] as int;
        final period = selected['period'] as String;
        final day = updatedDays.firstWhere(
            (d) => d['dayNumber'] == dayNumber,
            orElse: () => {});
        if (day.isEmpty) continue;
        final delTimeRange = selected['timeRange'] as String? ?? '';
        (day['slots'] as List).removeWhere((s) {
          final slot = s as Map<String, dynamic>;
          return slot['period'] == period &&
              (delTimeRange.isEmpty || slot['timeRange'] == delTimeRange);
        });
      }

      // --- تبديل ---
      for (final selected in _selectedSlots) {
        final dayNumber = selected['dayNumber'] as int;
        final period = selected['period'] as String;

        final day = updatedDays.firstWhere(
            (d) => d['dayNumber'] == dayNumber,
            orElse: () => {});
        if (day.isEmpty) continue;

        final slots = day['slots'] as List;
        final timeRange = selected['timeRange'] as String? ?? '';
        final slotIndex = slots.indexWhere((s) {
          final slot = s as Map<String, dynamic>;
          return slot['period'] == period &&
              (timeRange.isEmpty || slot['timeRange'] == timeRange);
        });
        if (slotIndex == -1) continue;

        final currentSlot =
            Map<String, dynamic>.from(slots[slotIndex] as Map);
        final type = _normalizeType(
            currentSlot['type'] as String? ?? 'activity');

        // جيب كل venues بدون limit
        final venuesSnap = await FirebaseFirestore.instance
            .collection('venues')
            .get();

        final alternatives = venuesSnap.docs.where((d) {
          final data = d.data();
          final venueCity =
              (_venueField(data, 'city') ?? '').toLowerCase().trim();
          final venueType =
              (_venueField(data, 'venueType') ?? '').toLowerCase().trim();
          final venueName =
              (_venueField(data, 'name') ?? '').toLowerCase().trim();
          return venueCity == city.toLowerCase().trim() &&
              venueType == type &&
              !usedNames.contains(venueName);
        }).toList();

        if (alternatives.isEmpty) continue;

        alternatives.shuffle();
        final newVenue = alternatives.first.data();
        final newName = _venueField(newVenue, 'name') ??
            (currentSlot['name'] as String? ?? '');
        final newDesc = _venueField(newVenue, 'description') ??
            (currentSlot['description'] as String? ?? '');
        final newMaps =
            _venueField(newVenue, 'mapsLink') ?? '$newName, $city';

        slots[slotIndex] = {
          ...currentSlot,
          'name': newName,
          'description': newDesc,
          'location': {
            'name': newName,
            'area': city,
            'mapsQuery': newMaps,
          },
          'tips': [],
        };

        usedNames.add(newName.toLowerCase());
      }

      itineraryCopy['days'] = updatedDays;

      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update({
        'itinerary': jsonEncode(itineraryCopy),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _isRegenerating = false;
        _isEditMode = false;
        _selectedSlots.clear();
        _selectedForDelete.clear();
        _itineraryVersion++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Your plan has been updated!',
                style: TextStyle(fontWeight: FontWeight.w500)),
          ]),
          backgroundColor: const Color(0xFF006E51),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRegenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      _listenToTrip();
    }
  }

  Future<void> _savePlan() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update({'saved': true});
      setState(() => _isSaved = true);
      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFF006E51))));
    }

    if (_error != null && _itinerary == null) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: const Color(0xFF006E51),
            foregroundColor: Colors.white,
            title: const Text('Itinerary')),
        body: Center(
            child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }

    if (_tabController == null) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFF006E51))));
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
              // زر Start This Trip — يختفي في وضع التعديل
              if (!_isEditMode) ...[
                GestureDetector(
                  onTap: _isSaving ? null : _savePlan,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF006E51), Color(0xFFA384DA)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
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
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // زر Edit Plan / Update / Cancel
              GestureDetector(
                onTap: () {
                  if (!_isEditMode) {
                    setState(() => _isEditMode = true);
                  } else if (_selectedSlots.isNotEmpty ||
                      _selectedForDelete.isNotEmpty) {
                    _showReviewSheet();
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
                    ),
                  ),
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
                    colors: [Color(0xFF006E51), Color(0xFFA384DA)],
                  ),
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
                              borderRadius: BorderRadius.circular(20),
                            ),
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
              controller: _tabController!,
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
          controller: _tabController!,
          children: days
              .map((d) => _buildDayTab(d as Map<String, dynamic>))
              .toList(),
        ),
      ),
    );
  }

  double _calculateExpandedHeight(
      String title, String summary, Map<String, dynamic>? totalCost) {
    double height = 180;
    if (title.length > 40) height += 24;
    if (title.length > 80) height += 24;
    if (summary.length > 80) height += 20;
    if (summary.length > 160) height += 20;
    if (summary.length > 240) height += 20;
    if (totalCost != null) height += 44;
    return height;
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
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
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
                          .toList(),
                    ),
                  ),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006E51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Map',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
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
    final icon = _slotIcon(type);
    final periodIcon = _periodIcon(period);
    final isSelected = _selectedSlots.any((s) =>
        s['dayNumber'] == dayNumber && s['period'] == period && s['timeRange'] == timeRange);
    final isDeleteSelected = _selectedForDelete.any((s) =>
        s['dayNumber'] == dayNumber && s['period'] == period && s['timeRange'] == timeRange);

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
            width: (isSelected || isDeleteSelected) ? 2 : 1),
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
                    const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(
              children: [
                Icon(periodIcon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                    child: Text('$period  •  $timeRange',
                        style: TextStyle(
                            fontSize: 13,
                            color: color,
                            fontWeight: FontWeight.w500))),
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(type, style: TextStyle(fontSize: 12, color: color)),
                // الأيقونات تظهر فقط في وضع التعديل
                if (!_isSaved && _isEditMode) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _toggleSlot(dayNumber, period, name, timeRange),
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
                        color: isSelected ? const Color(0xFFA384DA) : color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _toggleDelete(dayNumber, period, name, timeRange),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDeleteSelected
                            ? Colors.red.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isDeleteSelected ? Icons.delete : Icons.delete_outline,
                        size: 16,
                        color: isDeleteSelected ? Colors.red : Colors.grey,
                      ),
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
                        child: Text(
                            '${location['name']}, ${location['area']}',
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
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _showVenueDetails(String venueName) async {
    // جيب بيانات الفعالية من Firestore
    Map<String, dynamic>? venueData;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('venues')
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final name = _venueField(data, 'name') ?? '';
        if (name.toLowerCase() == venueName.toLowerCase()) {
          venueData = data;
          break;
        }
      }
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        final name = venueData != null
            ? (_venueField(venueData, 'name') ?? venueName)
            : venueName;
        final description = venueData != null
            ? (_venueField(venueData, 'description') ?? '')
            : '';
        final city = venueData != null
            ? (_venueField(venueData, 'city') ?? '')
            : '';
        final type = venueData != null
            ? (_venueField(venueData, 'Type') ?? _venueField(venueData, 'type') ?? '')
            : '';
        final mapsLink = venueData != null
            ? (_venueField(venueData, 'mapsLink') ?? '')
            : '';
        final rateRaw = venueData?['Rate'] ?? venueData?['rate'];
        final rate = rateRaw != null ? rateRaw.toString() : null;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Name
                Text(name,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 8),
                // Rating
                if (rate != null)
                  Row(children: [
                    const Icon(Icons.star, color: Color(0xFFFFB800), size: 18),
                    const SizedBox(width: 4),
                    Text(rate,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    const SizedBox(width: 4),
                    Text('/ 5',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ]),
                if (rate != null) const SizedBox(height: 12),
                // Type & City chips
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
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[700])),
                      backgroundColor: Colors.grey[100],
                      padding: EdgeInsets.zero,
                    ),
                ]),
                const SizedBox(height: 16),
                // Description
                if (description.isNotEmpty) ...[
                  const Text('About',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  const SizedBox(height: 6),
                  Text(description,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5)),
                  const SizedBox(height: 20),
                ],
                // Google Maps button
                if (mapsLink.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(mapsLink);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF006E51),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Open in Google Maps',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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