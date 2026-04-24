import 'package:flutter/material.dart';
import '../../models/trip_preferences.dart';
import '../../widgets/custom_widgets.dart';

class BudgetStep extends StatefulWidget {
  final TripPreferences preferences;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const BudgetStep(
      {Key? key,
      required this.preferences,
      required this.onContinue,
      required this.onBack})
      : super(key: key);

  @override
  State<BudgetStep> createState() => _BudgetStepState();
}

class _BudgetStepState extends State<BudgetStep> {
  final List<Map<String, dynamic>> _budgets = [
    {
      'title': 'Economy',
      'subtitle': '100 - 300 SAR',
      'value': 'economy',
      'icon': Icons.savings_outlined
    },
    {
      'title': 'Mid-range',
      'subtitle': '300 - 600 SAR',
      'value': 'mid-range',
      'icon': Icons.account_balance_wallet_outlined
    },
    {
      'title': 'Comfort',
      'subtitle': '600 - 1000 SAR',
      'value': 'comfort',
      'icon': Icons.star_outline
    },
    {
      'title': 'Luxury',
      'subtitle': '1000+ SAR',
      'value': 'luxury',
      'icon': Icons.diamond_outlined
    },
  ];

  String _selectedBudget = '';

  @override
  void initState() {
    super.initState();
    _selectedBudget = widget.preferences.budget;
  }

  void _handleContinue() {
    if (_selectedBudget.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a budget range'),
            backgroundColor: Colors.red),
      );
      return;
    }
    widget.preferences.budget = _selectedBudget;
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose your budget',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey)),
          const SizedBox(height: 24),
          ...(_budgets.map((item) {
            final isSelected = _selectedBudget == item['value'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedBudget = item['value']),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF006E51), Color(0xFFA384DA)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : const Color(0xFFE0E0E0),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFF006E51).withOpacity(0.25)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: isSelected ? 12 : 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : const Color(0xFF006E51).withOpacity(0.08),
                          ),
                          child: Icon(item['icon'] as IconData,
                              size: 22,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF006E51)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                item['subtitle'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.8)
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected ? Colors.white : Colors.grey[300],
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 32),
          CustomButton(text: 'Continue', onPressed: _handleContinue),
        ],
      ),
    );
  }
}
