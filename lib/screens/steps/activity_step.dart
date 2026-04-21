import 'package:flutter/material.dart';
import '../../models/trip_preferences.dart';
import '../../widgets/custom_widgets.dart';

class ActivityStep extends StatefulWidget {
  final TripPreferences preferences;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const ActivityStep({
    Key? key,
    required this.preferences,
    required this.onContinue,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ActivityStep> createState() => _ActivityStepState();
}

class _ActivityStepState extends State<ActivityStep> {
  final List<String> _activities = [
    'Cultural & Historical',
    'Natural Sites & outdoors',
    'Family-Friendly Entertainment',
    'Art & Creativity',
    'Shopping',
    'Sports & Adventures',
  ];

  Set<String> _selectedActivities = {};

  @override
  void initState() {
    super.initState();
    _selectedActivities = Set.from(widget.preferences.activities);
  }

  void _toggleActivity(String activity) {
    setState(() {
      if (_selectedActivities.contains(activity)) {
        _selectedActivities.remove(activity);
      } else {
        _selectedActivities.add(activity);
      }
    });
  }

  void _handleContinue() {
    if (_selectedActivities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one activity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.preferences.activities = _selectedActivities.toList();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose activity you like',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Activity List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activities.length,
            itemBuilder: (context, index) {
              final activity = _activities[index];
              final isSelected = _selectedActivities.contains(activity);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _toggleActivity(activity),
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? const Color(0xFF006E51) : const Color(0xFFA384DA),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      color: isSelected ? const Color(0xFF006E51).withOpacity(0.05) : Colors.white,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF006E51) : Colors.grey[400]!,
                              width: 2,
                            ),
                            color: isSelected ? const Color(0xFF006E51) : Colors.white,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            activity,
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected ? const Color(0xFF006E51) : Colors.black87,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Continue Button
          CustomButton(
            text: 'Continue',
            onPressed: _handleContinue,
          ),
        ],
      ),
    );
  }
}