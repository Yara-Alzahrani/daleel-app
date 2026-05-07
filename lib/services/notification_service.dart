import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
    );
  }

  static Future<void> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  // ── إشعار فوري عند حفظ الرحلة ────────────────────────────────────────────
  static Future<void> _showTripSavedNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'trip_saved_channel',
      'Trip Saved',
      channelDescription: 'إشعار حفظ الرحلة',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.show(
      999999,
      '✅ تم حفظ رحلتك!',
      'سيصلك تذكير قبل كل فعالية بـ 30 دقيقة',
      const NotificationDetails(android: androidDetails),
    );
  }

  // ── جدولة إشعار لفعالية واحدة (قبل 30 دقيقة) ────────────────────────────
  static Future<void> _scheduleEventNotification({
    required int id,
    required String title,
    required String city,
    required String dateStr,
    required String timeRange,
    int minutesBefore = 30,
  }) async {
    final startTime = timeRange.split(' - ').first.trim();
    final tp = startTime.split(':');
    if (tp.length < 2) return;

    final dp = dateStr.split('-');
    if (dp.length < 3) return;

    final eventTime = tz.TZDateTime(
      tz.local,
      int.parse(dp[0]),
      int.parse(dp[1]),
      int.parse(dp[2]),
      int.parse(tp[0]),
      int.parse(tp[1]),
    );

    final notifyTime = eventTime.subtract(Duration(minutes: minutesBefore));
    if (notifyTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
      'trip_events_channel',
      'Trip Events',
      channelDescription: 'تذكيرات فعاليات رحلتك',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.zonedSchedule(
      id,
      '⏰ $title',
      '$city  •  $timeRange',
      notifyTime,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── جدول كل فعاليات الرحلة + إشعار فوري + حفظ محلي ─────────────────────
  static Future<void> scheduleAndSaveTrip({
    required String tripId,
    required List<dynamic> days,
    required String city,
  }) async {
    await requestPermission();

    // إشعار فوري عند الحفظ
    await _showTripSavedNotification();

    final prefs = await SharedPreferences.getInstance();
    final existing = _loadList(prefs);

    final base = tripId.hashCode.abs() % 10000;
    int counter = 0;

    for (final d in days) {
      final day = d as Map<String, dynamic>;
      final dateStr = day['date'] as String? ?? '';
      final slots = day['slots'] as List? ?? [];

      for (final s in slots) {
        final slot = s as Map<String, dynamic>;
        final name = slot['name'] as String? ?? '';
        final timeRange = slot['timeRange'] as String? ?? '';
        if (name.isEmpty || timeRange.isEmpty || dateStr.isEmpty) continue;

        // جدول إشعار قبل 30 دقيقة من كل فعالية
        await _scheduleEventNotification(
          id: (base + counter) % 2147483647,
          title: name,
          city: city,
          dateStr: dateStr,
          timeRange: timeRange,
          minutesBefore: 30,
        );

        // احفظ محلياً بدون تكرار
        final alreadyExists = existing.any((e) =>
            e['tripId'] == tripId &&
            e['name'] == name &&
            e['timeRange'] == timeRange);

        if (!alreadyExists) {
          existing.insert(0, {
            'tripId': tripId,
            'name': name,
            'city': city,
            'date': dateStr,
            'timeRange': timeRange,
            'savedAt': DateTime.now().toIso8601String(),
          });
        }

        counter++;
      }
    }

    await prefs.setString('trip_notifications', jsonEncode(existing));
  }

  // ── قراءة الإشعارات المحفوظة ──────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getSavedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadList(prefs);
  }

  // ── helper ────────────────────────────────────────────────────────────────
  static List<Map<String, dynamic>> _loadList(SharedPreferences prefs) {
    final raw = prefs.getString('trip_notifications') ?? '[]';
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
