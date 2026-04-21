import 'package:flutter/material.dart';
import '../../models/trip_preferences.dart';
import '../../widgets/custom_widgets.dart';

class RestaurantStep extends StatefulWidget {
  final TripPreferences preferences;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const RestaurantStep({
    Key? key,
    required this.preferences,
    required this.onContinue,
    required this.onBack,
  }) : super(key: key);

  @override
  State<RestaurantStep> createState() => _RestaurantStepState();
}

class _RestaurantStepState extends State<RestaurantStep> {
  final List<String> _restaurants = [
    'Saudi Traditional',
    'Arab (Levantine - Egyptian)',
    'International (Italian - French - American)',
    'Asian (Chinese - Indian - Japanese)',
    'Seafood',
    'Fast Food',
    'Desserts & Cafes',
  ];

  Set<String> _selectedRestaurants = {};

  @override
  void initState() {
    super.initState();
    _selectedRestaurants = Set.from(widget.preferences.restaurants);
  }

  void _toggleRestaurant(String restaurant) {
    setState(() {
      if (_selectedRestaurants.contains(restaurant)) {
        _selectedRestaurants.remove(restaurant);
      } else {
        _selectedRestaurants.add(restaurant);
      }
    });
  }

  void _handleContinue() {
    if (_selectedRestaurants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one restaurant type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.preferences.restaurants = _selectedRestaurants.toList();
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
            'Choose restaurant you like',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Restaurant List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = _restaurants[index];
              final isSelected = _selectedRestaurants.contains(restaurant);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _toggleRestaurant(restaurant),
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
                            restaurant,
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