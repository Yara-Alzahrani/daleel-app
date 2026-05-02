import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'day_map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // ✅ فلتر الرحلات الحالية فقط (مو منتهية)
  bool _isTripCurrent(Map<String, dynamic> trip) {
    final prefs = trip['preferences'] as Map<String, dynamic>? ?? {};
    final dateRange = prefs['dateRange'] as Map<String, dynamic>? ?? {};
    final endDateStr = dateRange['endDate'] as String? ?? '';
    if (endDateStr.isEmpty) return true;
    try {
      final endDate = DateTime.parse(endDateStr);
      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      return !endDate.isBefore(today);
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
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
        automaticallyImplyLeading: false,
        actions: [
          ClipOval(
            child: Image.asset(
              'assets/images/daleelfree.png',
              width: 85,
              height: 85,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF006E51), Color(0xFFA384DA)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back!',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 14)),
                const SizedBox(height: 4),
                const Text('Your Current Trips',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('trips')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF006E51)));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: ${snapshot.error}',
                        style:
                            const TextStyle(color: Colors.red, fontSize: 13)),
                  ));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(context);
                }

                final trips = snapshot.data!.docs.where((doc) {
                  final trip = doc.data() as Map<String, dynamic>;
                  return _isTripCurrent(trip);
                }).toList()
                  ..sort((a, b) {
                    final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return bTime.compareTo(aTime);
                  });

                if (trips.isEmpty) return _buildEmptyState(context);

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index].data() as Map<String, dynamic>;
                    final tripId = trips[index].id;
                    return _buildTripCard(context, tripId, trip);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/create-plan'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF006E51), Color(0xFFA384DA)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF006E51).withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white),
              SizedBox(width: 8),
              Text('New Trip',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(
      BuildContext context, String tripId, Map<String, dynamic> trip) {
    final prefs = trip['preferences'] as Map<String, dynamic>? ?? {};
    final city = prefs['city'] as String? ?? 'Unknown city';
    final dateRange = prefs['dateRange'] as Map<String, dynamic>? ?? {};
    final startDate = dateRange['startDate'] as String? ?? '';
    final endDate = dateRange['endDate'] as String? ?? '';
    final numberOfDays = dateRange['numberOfDays'] as int? ?? 0;
    final travelers = prefs['travelers'] as Map<String, dynamic>? ?? {};
    final adults = travelers['adults'] as int? ?? 0;
    final children = travelers['children'] as int? ?? 0;
    final budget = prefs['budget'] as Map<String, dynamic>? ?? {};
    final budgetTier = budget['tier'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.18), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF006E51).withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF006E51).withOpacity(0.1),
                  ),
                  child: const Icon(Icons.location_on,
                      color: Color(0xFF006E51), size: 18),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF006E51), Color(0xFFA384DA)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child: Text(
                    city,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA384DA).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$numberOfDays days',
                      style: const TextStyle(
                          color: Color(0xFFA384DA),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmDelete(context, tripId),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: Color(0xFF006E51)),
                    const SizedBox(width: 6),
                    Text('$startDate → $endDate',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people_outline,
                        size: 14, color: Color(0xFFA384DA)),
                    const SizedBox(width: 6),
                    Text(
                      '$adults adult${adults != 1 ? 's' : ''}${children > 0 ? ', $children child${children != 1 ? 'ren' : ''}' : ''}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 14, color: Color(0xFFA384DA)),
                    const SizedBox(width: 6),
                    Text(budgetTier.toUpperCase(),
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: _ViewDetailsButton(
                      onTap: () => _showTripDetails(context, tripId, trip)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String tripId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Trip',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('trips')
                  .doc(tripId)
                  .delete();
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showTripDetails(
      BuildContext context, String tripId, Map<String, dynamic> trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TripDetailsSheet(tripId: tripId, trip: trip),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No trips yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('Tap "New Trip" to plan your first adventure',
              style: TextStyle(fontSize: 14, color: Colors.grey[400])),
        ],
      ),
    );
  }
}

// ── زر View Details مع تأثير الضغط ──────────────────────────────────────────
class _ViewDetailsButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ViewDetailsButton({required this.onTap});

  @override
  State<_ViewDetailsButton> createState() => _ViewDetailsButtonState();
}

class _ViewDetailsButtonState extends State<_ViewDetailsButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: _pressed
              ? const LinearGradient(
                  colors: [Color(0xFF006E51), Color(0xFFA384DA)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: _pressed ? null : const Color(0xFFA384DA).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View Details',
              style: TextStyle(
                color: _pressed ? Colors.white : const Color(0xFFA384DA),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward,
              size: 14,
              color: _pressed ? Colors.white : const Color(0xFFA384DA),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Sheet ──────────────────────────────────────────────────────────────
class _TripDetailsSheet extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic> trip;
  const _TripDetailsSheet({required this.tripId, required this.trip});

  @override
  State<_TripDetailsSheet> createState() => _TripDetailsSheetState();
}

class _TripDetailsSheetState extends State<_TripDetailsSheet>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _itinerary;
  bool _isLoading = true;
  String _status = '';
  TabController? _tabController;

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
      final data = doc.data() ?? {};
      final itineraryRaw = data['itinerary'];
      final status = data['status'] as String? ?? '';
      if (itineraryRaw != null) {
        final itinerary = itineraryRaw is String
            ? jsonDecode(itineraryRaw) as Map<String, dynamic>
            : itineraryRaw as Map<String, dynamic>;
        final days = itinerary['days'] as List? ?? [];
        setState(() {
          _itinerary = itinerary;
          _status = status;
          _tabController = TabController(length: days.length, vsync: this);
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F8F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF006E51), Color(0xFFA384DA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      (widget.trip['preferences']
                              as Map<String, dynamic>?)?['city'] ??
                          '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF006E51))))
              else if (_itinerary == null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _status == 'pending'
                                ? Icons.hourglass_top_rounded
                                : Icons.map_outlined,
                            size: 56,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _status == 'pending'
                                ? 'Your plan is being generated...'
                                : 'Itinerary not available',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.of(context).pushNamed('/itinerary',
                                  arguments: widget.tripId);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF006E51),
                                    Color(0xFFA384DA)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: const Text('Open Full Plan',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: const Color(0xFF006E51),
                    labelColor: const Color(0xFF006E51),
                    unselectedLabelColor: Colors.grey,
                    tabs: List.generate((_itinerary!['days'] as List).length,
                        (i) {
                      final day = (_itinerary!['days'] as List)[i]
                          as Map<String, dynamic>;
                      return Tab(text: 'Day ${day['dayNumber']}');
                    }),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: (_itinerary!['days'] as List).map((d) {
                      final day = d as Map<String, dynamic>;
                      return _buildDayTab(day, scrollController);
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayTab(
      Map<String, dynamic> day, ScrollController scrollController) {
    final slots = day['slots'] as List? ?? [];
    final theme = day['theme'] as String? ?? '';
    final date = day['date'] as String? ?? '';
    final dayNumber = day['dayNumber'] as int? ?? 0;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF006E51).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
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
                            fontSize: 15,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006E51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined,
                          color: Colors.white, size: 14),
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
        const SizedBox(height: 12),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(periodIcon, size: 15, color: color),
                const SizedBox(width: 6),
                Expanded(
                    child: Text('$period  •  $timeRange',
                        style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w500))),
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 4),
                Text(type, style: TextStyle(fontSize: 11, color: color)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text(description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                if (location != null) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Color(0xFF006E51)),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text('${location['name']}, ${location['area']}',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF006E51)))),
                  ]),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  if (duration.isNotEmpty) ...[
                    const Icon(Icons.access_time, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(duration,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 12),
                  ],
                  if (cost != null) ...[
                    const Icon(Icons.attach_money,
                        size: 13, color: Colors.grey),
                    Flexible(
                        child: Text(
                      cost['amount'] == 0
                          ? 'Free'
                          : '${cost['amount']} ${cost['currency']}${cost['perPerson'] == true ? '/person' : ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )),
                  ],
                ]),
                if (tips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 6),
                  const Text('Tips',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA384DA))),
                  const SizedBox(height: 4),
                  ...tips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(color: Color(0xFFA384DA))),
                              Expanded(
                                  child: Text(tip.toString(),
                                      style: TextStyle(
                                          fontSize: 12,
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
