import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItineraryScreen extends StatefulWidget {
  final String tripId;
  const ItineraryScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _itinerary;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  bool _isSaved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadItinerary();
  }

  Future<void> _loadItinerary() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Trip not found.';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      final itineraryRaw = data['itinerary'];

      if (itineraryRaw == null) {
        setState(() {
          _error = 'Itinerary not generated yet.';
          _isLoading = false;
        });
        return;
      }

      final itinerary = itineraryRaw is String
          ? jsonDecode(itineraryRaw) as Map<String, dynamic>
          : itineraryRaw as Map<String, dynamic>;

      final days = itinerary['days'] as List? ?? [];

      setState(() {
        _itinerary = itinerary;
        _isSaved = data['saved'] == true;
        _isLoading = false;
        _tabController = TabController(length: days.length, vsync: this);
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load itinerary: $e';
        _isLoading = false;
      });
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
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    if (!_isLoading && _error == null) _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFF006E51))));
    }

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
            if (!_isSaved)
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
              )
            else
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
              ),
            const SizedBox(height: 10),
            if (!_isSaved)
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF006E51).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined,
                          color: Color(0xFF006E51), size: 18),
                      SizedBox(width: 8),
                      Text('Edit Plan',
                          style: TextStyle(
                              color: Color(0xFF006E51),
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
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
                            // ✅ الإصلاح: أضفنا maxLines و overflow لمنع الـ overflow
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
          controller: _tabController,
          children:
              days.map((d) => _buildDayTab(d as Map<String, dynamic>)).toList(),
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...slots.map((s) => _buildSlotCard(s as Map<String, dynamic>)).toList(),
      ],
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
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
                color: color.withOpacity(0.1),
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
