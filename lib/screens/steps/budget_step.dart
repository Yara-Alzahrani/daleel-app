import 'package:flutter/material.dart';
import '../../models/trip_preferences.dart';
import '../../widgets/custom_widgets.dart';

class BudgetStep extends StatefulWidget {
  final TripPreferences preferences;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const BudgetStep({
    Key? key,
    required this.preferences,
    required this.onContinue,
    required this.onBack,
  }) : super(key: key);

  @override
  State<BudgetStep> createState() => _BudgetStepState();
}

class _BudgetStepState extends State<BudgetStep> {
  final List<Map<String, String>> _budgets = [
    {
      'title': 'Economy: 100 - 300 SAR',
      'value': 'economy',
    },
    {
      'title': 'Mid-range: 300 - 600 SAR',
      'value': 'mid-range',
    },
    {
      'title': 'Comfort: 600 - 1000 SAR',
      'value': 'comfort',
    },
    {
      'title': 'Luxury: 1000+ SAR',
      'value': 'luxury',
    },
  ];

  String _selectedBudget = '';

  @override
  void initState() {
    super.initState();
    _selectedBudget = widget.preferences.budget;
  }

  void _selectBudget(String budget) {
    setState(() {
      _selectedBudget = budget;
    });
  }

  void _handleContinue() {
    if (_selectedBudget.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a budget range'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.preferences.budget = _selectedBudget;
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
            'Choose budget you like',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Budget List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _budgets.length,
            itemBuilder: (context, index) {
              final budget = _budgets[index];
              final isSelected = _selectedBudget == budget['value'];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _selectBudget(budget['value']!),
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
                              ? Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            budget['title']!,
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

          // Create Button
          CustomButton(
            text: 'Create',
            onPressed: _handleContinue,
          ),
        ],
      ),
    );
  }
}