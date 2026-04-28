import 'package:flutter/material.dart';
import '../models/trip_preferences.dart';
import 'steps/general_info_step.dart';
import 'steps/activity_step.dart';
import 'steps/restaurant_step.dart';
import 'steps/budget_step.dart';
import 'steps/create_step.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({Key? key}) : super(key: key);

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  int _currentStep = 0;
  final TripPreferences _preferences = TripPreferences();

  final List<IconData> _stepIcons = [
    Icons.info_outline,
    Icons.local_activity_outlined,
    Icons.restaurant_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.rocket_launch_outlined,
  ];

  void _nextStep() {
    if (_currentStep < 4) setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _onStepTapped(int step) {
    setState(() => _currentStep = step);
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return GeneralInfoStep(
            preferences: _preferences, onContinue: _nextStep);
      case 1:
        return ActivityStep(
            preferences: _preferences,
            onContinue: _nextStep,
            onBack: _previousStep);
      case 2:
        return RestaurantStep(
            preferences: _preferences,
            onContinue: _nextStep,
            onBack: _previousStep);
      case 3:
        return BudgetStep(
            preferences: _preferences,
            onContinue: _nextStep,
            onBack: _previousStep);
      case 4:
        return CreateStep(preferences: _preferences, onBack: _previousStep);
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006E51),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          // ✅ لو في أول step يرجع للهوم، غير كذلك يرجع للـ step اللي قبله
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Create a Plan',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Stepper Header ──────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF006E51),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Row(
              children: List.generate(5, (index) {
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;

                return Expanded(
                  child: Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isCompleted
                                    ? [
                                        const Color(0xFF006E51),
                                        const Color(0xFFA384DA)
                                      ]
                                    : [
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.2)
                                      ],
                              ),
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () => _onStepTapped(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isActive ? 48 : 38,
                          height: isActive ? 48 : 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isCompleted
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF006E51),
                                      Color(0xFFA384DA)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isCompleted
                                ? null
                                : isActive
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.15),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check_rounded,
                                    size: 20, color: Colors.white)
                                : Icon(
                                    _stepIcons[index],
                                    size: isActive ? 24 : 17,
                                    color: isActive
                                        ? const Color(0xFF006E51)
                                        : Colors.white.withOpacity(0.6),
                                  ),
                          ),
                        ),
                      ),
                      if (index < 4)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? const Color(0xFFA384DA)
                                : Colors.white.withOpacity(0.2),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),

          Expanded(child: _buildStep()),
        ],
      ),
    );
  }
}
