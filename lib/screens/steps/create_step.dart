import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../models/trip_preferences.dart';
import '../../services/app_config.dart';
import '../../widgets/custom_widgets.dart';

class CreateStep extends StatefulWidget {
  final TripPreferences preferences;
  final VoidCallback onBack;

  const CreateStep({
    Key? key,
    required this.preferences,
    required this.onBack,
  }) : super(key: key);

  @override
  State<CreateStep> createState() => _CreateStepState();
}

class _CreateStepState extends State<CreateStep> {
  bool _isCreating = false;

  Future<void> _createPlan() async {
    setState(() => _isCreating = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final prefs = widget.preferences;
      final numberOfDays =
          prefs.endDate!.difference(prefs.startDate!).inDays + 1;

      final budgetRange = AppConfig.budgetRanges[prefs.budget] ?? '';

      // Build the nested Firestore document
      final tripData = {
        'userId': user.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'preferences': {
          'city': prefs.city,
          'travelers': {
            'adults': prefs.numberOfParents,
            'children': prefs.numberOfChildren,
          },
          'dateRange': {
            'startDate': prefs.startDate!.toIso8601String().substring(0, 10),
            'endDate': prefs.endDate!.toIso8601String().substring(0, 10),
            'numberOfDays': numberOfDays,
          },
          'activities': prefs.activities,
          'restaurants': prefs.restaurants,
          'budget': {
            'tier': prefs.budget,
            'range': budgetRange,
            'currency': 'SAR',
          },
        },
        'itinerary': null,
        'errorMessage': null,
      };

      // 1. Write to Firestore
      final docRef =
          await FirebaseFirestore.instance.collection('trips').add(tripData);

      // 2. Call n8n webhook (fire and forget — n8n will write result back)
      _callWebhook(docRef.id, user.uid, prefs, numberOfDays, budgetRange);

      if (!mounted) return;

      // 3. Navigate to loading screen, passing the tripId
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/trip-loading',
        (route) => false,
        arguments: docRef.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isCreating = false);
    }
  }

  // Calls the n8n webhook without blocking the UI.
  // n8n will write the itinerary back to Firestore asynchronously.
  Future<void> _callWebhook(
    String tripId,
    String userId,
    TripPreferences prefs,
    int numberOfDays,
    String budgetRange,
  ) async {
    try {
      final body = jsonEncode({
        'tripId': tripId,
        'userId': userId,
        'preferences': {
          'city': prefs.city,
          'travelers': {
            'adults': prefs.numberOfParents,
            'children': prefs.numberOfChildren,
          },
          'dateRange': {
            'startDate': prefs.startDate!.toIso8601String().substring(0, 10),
            'endDate': prefs.endDate!.toIso8601String().substring(0, 10),
            'numberOfDays': numberOfDays,
          },
          'activities': prefs.activities,
          'restaurants': prefs.restaurants,
          'budget': {
            'tier': prefs.budget,
            'range': budgetRange,
            'currency': 'SAR',
          },
        },
      });

      await http.post(
        Uri.parse(AppConfig.n8nWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
    } catch (_) {
      // Webhook failure is non-fatal — n8n can be retried manually.
      // The trip doc is already in Firestore with status='pending'.
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Your Plan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA384DA), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('City', widget.preferences.city),
                const Divider(height: 24),
                _buildInfoRow(
                  'Travel Dates',
                  '${_formatDate(widget.preferences.startDate)} - ${_formatDate(widget.preferences.endDate)}',
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  'Travelers',
                  '${widget.preferences.numberOfParents} Adult(s), ${widget.preferences.numberOfChildren} Child(ren)',
                ),
                const Divider(height: 24),
                _buildInfoRow(
                    'Budget', widget.preferences.budget.toUpperCase()),
                const Divider(height: 24),
                _buildListRow('Activities', widget.preferences.activities),
                const Divider(height: 24),
                _buildListRow('Restaurants', widget.preferences.restaurants),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // AI Generation Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE381).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF006E51)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Our AI will create a personalized itinerary based on your preferences',
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          CustomButton(
            text: _isCreating ? 'Creating...' : 'Create My Plan',
            onPressed: _isCreating ? () {} : _createPlan,
            isLoading: _isCreating,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF006E51),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildListRow(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF006E51),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFA384DA).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
