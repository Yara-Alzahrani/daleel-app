import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PastPlansScreen extends StatelessWidget {
  const PastPlansScreen({Key? key}) : super(key: key);

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
            child: const Text(
              'Your Past Trips',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('trips')
                  .where('userId', isEqualTo: user.uid)
                  .where('saved', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF006E51)));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red)));
                }

                final pastTrips = snapshot.data?.docs ?? [];

                if (pastTrips.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: pastTrips.length,
                  itemBuilder: (context, index) {
                    final trip =
                        pastTrips[index].data() as Map<String, dynamic>;
                    final tripId = pastTrips[index].id;
                    return _buildTripCard(context, tripId, trip);
                  },
                );
              },
            ),
          ),
        ],
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
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF006E51).withOpacity(0.7),
                  const Color(0xFFA384DA).withOpacity(0.7)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(city,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Colors.white, size: 13),
                      const SizedBox(width: 4),
                      Text('$numberOfDays days',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ],
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showTripDetails(context, prefs),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA384DA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline,
                                  size: 14, color: Color(0xFFA384DA)),
                              SizedBox(width: 6),
                              Text('Trip Details',
                                  style: TextStyle(
                                      color: Color(0xFFA384DA),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context)
                            .pushNamed('/itinerary', arguments: tripId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006E51).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined,
                                  size: 14, color: Color(0xFF006E51)),
                              SizedBox(width: 6),
                              Text('View Plan',
                                  style: TextStyle(
                                      color: Color(0xFF006E51),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTripDetails(BuildContext context, Map<String, dynamic> prefs) {
    final dateRange = prefs['dateRange'] as Map<String, dynamic>? ?? {};
    final travelers = prefs['travelers'] as Map<String, dynamic>? ?? {};
    final budget = prefs['budget'] as Map<String, dynamic>? ?? {};
    final activities = prefs['activities'] as List<dynamic>? ?? [];
    final restaurants = prefs['restaurants'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(prefs['city'] as String? ?? 'Trip Details',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006E51))),
                  const SizedBox(height: 20),
                  _buildDetailRow(Icons.calendar_today_outlined, 'Dates',
                      '${dateRange['startDate']} → ${dateRange['endDate']} (${dateRange['numberOfDays']} days)'),
                  _buildDetailRow(Icons.people_outline, 'Travelers',
                      '${travelers['adults']} adults, ${travelers['children']} children'),
                  _buildDetailRow(
                      Icons.account_balance_wallet_outlined,
                      'Budget',
                      (budget['tier'] as String? ?? '').toUpperCase()),
                  if (activities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildChipsSection(
                        'Activities', activities, const Color(0xFF006E51)),
                  ],
                  if (restaurants.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildChipsSection(
                        'Restaurants', restaurants, const Color(0xFFA384DA)),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF006E51)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipsSection(String title, List<dynamic> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(item.toString(),
                  style: TextStyle(
                      fontSize: 13, color: color, fontWeight: FontWeight.w500)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No past trips yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('Your completed trips will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[400])),
        ],
      ),
    );
  }
}
