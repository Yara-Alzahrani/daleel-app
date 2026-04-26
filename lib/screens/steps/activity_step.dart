import 'package:flutter/material.dart';
import '../../models/trip_preferences.dart';
import '../../widgets/custom_widgets.dart';

class ActivityStep extends StatefulWidget {
  final TripPreferences preferences;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const ActivityStep(
      {Key? key,
      required this.preferences,
      required this.onContinue,
      required this.onBack})
      : super(key: key);

  @override
  State<ActivityStep> createState() => _ActivityStepState();
}

class _ActivityStepState extends State<ActivityStep> {
  final List<Map<String, dynamic>> _activities = [
    {'label': 'Cultural & Historical', 'icon': Icons.account_balance_outlined},
    {'label': 'Natural Sites & Outdoors', 'icon': Icons.park_outlined},
    {
      'label': 'Family-Friendly Entertainment',
      'icon': Icons.family_restroom_outlined
    },
    {'label': 'Art & Creativity', 'icon': Icons.palette_outlined},
    {'label': 'Shopping', 'icon': Icons.shopping_bag_outlined},
    {'label': 'Sports & Adventures', 'icon': Icons.sports_outlined},
  ];

  Set<String> _selectedActivities = {};

  @override
  void initState() {
    super.initState();
    _selectedActivities = Set.from(widget.preferences.activities);
  }

  void _toggle(String label) {
    setState(() {
      if (_selectedActivities.contains(label))
        _selectedActivities.remove(label);
      else
        _selectedActivities.add(label);
    });
  }

  void _handleContinue() {
    if (_selectedActivities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select at least one activity'),
          backgroundColor: Colors.red));
      return;
    }
    widget.preferences.activities = _selectedActivities.toList();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose activities you like',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600])),
          const SizedBox(height: 24),
          ...(_activities.map((item) {
            final label = item['label'] as String;
            final icon = item['icon'] as IconData;
            final isSelected = _selectedActivities.contains(label);
            return _buildOptionCard(
                label: label,
                icon: icon,
                isSelected: isSelected,
                onTap: () => _toggle(label));
          }).toList()),
          const SizedBox(height: 32),
          CustomButton(text: 'Continue', onPressed: _handleContinue),
        ],
      ),
    );
  }
}

Widget _buildOptionCard(
    {required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              // أيقونة gradient لما تُختار
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF006E51), Color(0xFFA384DA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)
                      : null,
                  color: isSelected
                      ? null
                      : const Color(0xFF006E51).withOpacity(0.08),
                ),
                child: Icon(icon,
                    size: 20,
                    color: isSelected ? Colors.white : const Color(0xFF006E51)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                        color: Colors.black87)),
              ),
              // دائرة gradient لما تُختار
              if (isSelected)
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF006E51), Color(0xFFA384DA)])
                      .createShader(bounds),
                  child: const Icon(Icons.check_circle,
                      color: Colors.white, size: 22),
                )
              else
                Icon(Icons.circle_outlined, color: Colors.grey[300], size: 22),
            ],
          ),
        ),
      ),
    ),
  );
}
