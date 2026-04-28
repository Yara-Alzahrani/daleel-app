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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a budget range'),
          backgroundColor: Colors.red));
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
          Text('Choose your budget',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600])),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      border: Border.all(
                          color: const Color(0xFFE0E0E0), width: 1.5),
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [
                                        Color(0xFF006E51),
                                        Color(0xFFA384DA)
                                      ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight)
                                : null,
                            color: isSelected
                                ? null
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
                              Text(item['title'],
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87)),
                              Text(item['subtitle'],
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        // دائرة gradient لما تُختار
                        if (isSelected)
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFF006E51),
                                  Color(0xFFA384DA)
                                ]).createShader(bounds),
                            child: const Icon(Icons.check_circle,
                                color: Colors.white, size: 22),
                          )
                        else
                          Icon(Icons.circle_outlined,
                              color: Colors.grey[300], size: 22),
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
