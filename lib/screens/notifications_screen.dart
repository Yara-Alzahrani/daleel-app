import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await NotificationService.getSavedNotifications();
    if (mounted)
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
  }

  bool _isUpcoming(Map<String, dynamic> n) {
    try {
      final dp = (n['date'] as String).split('-');
      final tp =
          (n['timeRange'] as String).split(' - ').first.trim().split(':');
      final dt = DateTime(int.parse(dp[0]), int.parse(dp[1]), int.parse(dp[2]),
          int.parse(tp[0]), int.parse(tp[1]));
      return dt.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String _timeLabel(Map<String, dynamic> n) {
    try {
      final dp = (n['date'] as String).split('-');
      final tp =
          (n['timeRange'] as String).split(' - ').first.trim().split(':');
      final dt = DateTime(int.parse(dp[0]), int.parse(dp[1]), int.parse(dp[2]),
          int.parse(tp[0]), int.parse(tp[1]));
      final diff = dt.difference(DateTime.now());
      if (diff.isNegative) {
        final ago = diff.abs();
        if (ago.inDays > 0) return '${ago.inDays}d ago';
        if (ago.inHours > 0) return '${ago.inHours}h ago';
        return '${ago.inMinutes}m ago';
      } else {
        if (diff.inDays > 0) return 'in ${diff.inDays} days';
        if (diff.inHours > 0) return 'in ${diff.inHours}h';
        return 'in ${diff.inMinutes}m';
      }
    } catch (_) {
      return n['timeRange'] as String? ?? '';
    }
  }

  String _periodIcon(Map<String, dynamic> n) {
    final timeRange = n['timeRange'] as String? ?? '';
    final startTime = timeRange.split(' - ').first.trim();
    final hour = int.tryParse(startTime.split(':').first) ?? 12;
    if (hour < 12) return '🌅';
    if (hour < 17) return '☀️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _notifications.where(_isUpcoming).toList();
    final past = _notifications.where((n) => !_isUpcoming(n)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF006E51), Color(0xFFA384DA)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFF7F8FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF006E51)))
          : _notifications.isEmpty
              ? _buildEmpty()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    if (upcoming.isNotEmpty) ...[
                      _buildSectionHeader('Upcoming', Icons.schedule_rounded,
                          const Color(0xFF006E51)),
                      const SizedBox(height: 10),
                      ...upcoming.map((n) => _buildCard(n, true)),
                      const SizedBox(height: 20),
                    ],
                    if (past.isNotEmpty) ...[
                      _buildSectionHeader(
                          'Past', Icons.history_rounded, Colors.grey),
                      const SizedBox(height: 10),
                      ...past.map((n) => _buildCard(n, false)),
                    ],
                  ],
                ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            )),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: color.withOpacity(0.2), thickness: 1)),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> n, bool upcoming) {
    final name = n['name'] as String? ?? '';
    final city = n['city'] as String? ?? '';
    final timeRange = n['timeRange'] as String? ?? '';
    final date = n['date'] as String? ?? '';
    final timeLabel = _timeLabel(n);
    final emoji = _periodIcon(n);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(
          color: upcoming
              ? const Color(0xFF006E51).withOpacity(0.15)
              : Colors.grey.withOpacity(0.1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: upcoming
                ? const Color(0xFF006E51).withOpacity(0.06)
                : Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // ── Emoji Circle ──────────────────────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: upcoming
                    ? const LinearGradient(
                        colors: [Color(0xFF006E51), Color(0xFFA384DA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: upcoming ? null : Colors.grey[100],
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),

            // ── Details ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color:
                                  upcoming ? Colors.black87 : Colors.grey[500],
                            )),
                      ),
                      if (upcoming) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF006E51), Color(0xFFA384DA)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Soon',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),

                  // City + Date
                  Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 13,
                        color: upcoming
                            ? const Color(0xFF006E51)
                            : Colors.grey[400]),
                    const SizedBox(width: 3),
                    Text('$city  ·  $date',
                        style: TextStyle(
                          fontSize: 12,
                          color: upcoming
                              ? const Color(0xFF006E51)
                              : Colors.grey[400],
                        )),
                  ]),
                  const SizedBox(height: 5),

                  // Time range + label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.access_time_rounded,
                            size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text(timeRange,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                      ]),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: upcoming
                              ? const Color(0xFFA384DA).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(timeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: upcoming
                                  ? const Color(0xFFA384DA)
                                  : Colors.grey[400],
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF006E51).withOpacity(0.1),
                  const Color(0xFFA384DA).withOpacity(0.1),
                ],
              ),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 40, color: Color(0xFF006E51)),
          ),
          const SizedBox(height: 20),
          const Text('No notifications yet',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 8),
          Text('Save a trip to get event reminders',
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
