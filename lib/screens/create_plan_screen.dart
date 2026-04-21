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

  final List<String> _stepTitles = [
    'General\nInfo',
    'Activity',
    'Restur\nant',
    'Budget',
    'Create',
  ];

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _onStepTapped(int step) {
    setState(() => _currentStep = step);
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return GeneralInfoStep(
          preferences: _preferences,
          onContinue: _nextStep,
        );
      case 1:
        return ActivityStep(
          preferences: _preferences,
          onContinue: _nextStep,
          onBack: _previousStep,
        );
      case 2:
        return RestaurantStep(
          preferences: _preferences,
          onContinue: _nextStep,
          onBack: _previousStep,
        );
      case 3:
        return BudgetStep(
          preferences: _preferences,
          onContinue: _nextStep,
          onBack: _previousStep,
        );
      case 4:
        return CreateStep(
          preferences: _preferences,
          onBack: _previousStep,
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFA384DA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create a plan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Stepper Header
          Container(
            color: const Color(0xFFA384DA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_stepTitles.length, (index) {
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;
                
                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (index > 0)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: isCompleted
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                              ),
                            ),
                          GestureDetector(
                            onTap: () => _onStepTapped(index),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive || isCompleted
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        size: 18,
                                        color: Color(0xFFA384DA),
                                      )
                                    : Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isActive
                                              ? const Color(0xFFA384DA)
                                              : Colors.transparent,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          if (index < _stepTitles.length - 1)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: isCompleted
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _stepTitles[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          // Step Content
          Expanded(
            child: _buildStep(),
          ),
        ],
      ),
    );
  }
}