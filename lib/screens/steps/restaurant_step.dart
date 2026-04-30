import 'package:flutter/material.dart';
import '../../models/trip_preferences.dart';
import '../../widgets/custom_widgets.dart';

class RestaurantStep extends StatefulWidget {
  final TripPreferences preferences;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const RestaurantStep(
      {Key? key,
      required this.preferences,
      required this.onContinue,
      required this.onBack})
      : super(key: key);

  @override
  State<RestaurantStep> createState() => _RestaurantStepState();
}

class _RestaurantStepState extends State<RestaurantStep> {
  final List<Map<String, dynamic>> _restaurants = [
    {'label': 'Saudi Traditional', 'icon': Icons.rice_bowl_outlined},
    {
      'label': 'Arab (Levantine - Egyptian)',
      'icon': Icons.kebab_dining_outlined
    },
    {
      'label': 'International (Italian - French - American)',
      'icon': Icons.dining_outlined
    },
    {
      'label': 'Asian (Chinese - Indian - Japanese)',
      'icon': Icons.ramen_dining_outlined
    },
    {'label': 'Seafood', 'icon': Icons.set_meal_outlined},
    {'label': 'Fast Food', 'icon': Icons.fastfood_outlined},
    {'label': 'Desserts & Cafes', 'icon': Icons.local_cafe_outlined},
  ];

  Set<String> _selectedRestaurants = {};

  @override
  void initState() {
    super.initState();
    _selectedRestaurants = Set.from(widget.preferences.restaurants);
  }

  void _toggle(String label) {
    setState(() {
      if (_selectedRestaurants.contains(label)) {
        _selectedRestaurants.remove(label);
      } else {
        _selectedRestaurants.add(label);
      }
    });
  }

  void _handleContinue() {
    if (_selectedRestaurants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select at least one restaurant type'),
          backgroundColor: Colors.red));
      return;
    }
    widget.preferences.restaurants = _selectedRestaurants.toList();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose restaurants you like',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          const SizedBox(height: 24),
          ...(_restaurants.map((item) {
            final label = item['label'] as String;
            final icon = item['icon'] as IconData;
            final isSelected = _selectedRestaurants.contains(label);
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
                          color: Colors.black87))),
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
