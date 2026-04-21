import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TripLoadingScreen extends StatefulWidget {
  final String tripId;

  const TripLoadingScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  State<TripLoadingScreen> createState() => _TripLoadingScreenState();
}

class _TripLoadingScreenState extends State<TripLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  StreamSubscription<DocumentSnapshot>? _tripSubscription;

  final List<String> _loadingMessages = [
    'Analyzing your preferences...',
    'Discovering the best spots in your city...',
    'Crafting your personalized itinerary...',
    'Adding local tips and recommendations...',
    'Almost ready!',
  ];
  int _messageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Cycle through loading messages every 3 seconds
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _loadingMessages.length;
        });
      }
    });

    _listenToTrip();
  }

  void _listenToTrip() {
    _tripSubscription = FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;

      final status = snapshot.data()?['status'] as String?;

      if (status == 'completed') {
        _tripSubscription?.cancel();
        Navigator.of(context).pushReplacementNamed(
          '/itinerary',
          arguments: widget.tripId,
        );
      } else if (status == 'failed') {
        _tripSubscription?.cancel();
        _showErrorDialog(
          snapshot.data()?['errorMessage'] as String? ??
              'Something went wrong. Please try again.',
        );
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Generation Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              );
            },
            child: const Text(
              'Go Home',
              style: TextStyle(color: Color(0xFF006E51)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tripSubscription?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo / spinner
              RotationTransition(
                turns: _animationController,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        Color(0xFF006E51),
                        Color(0xFFA384DA),
                        Color(0xFFFFE381),
                        Color(0xFF006E51),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF006E51).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.map_outlined,
                        size: 40,
                        color: Color(0xFF006E51),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              const Text(
                'Creating Your Itinerary',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006E51),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _loadingMessages[_messageIndex],
                  key: ValueKey(_messageIndex),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 48),

              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _messageIndex % 5 ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _messageIndex % 5
                          ? const Color(0xFF006E51)
                          : const Color(0xFFA384DA).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 64),

              Text(
                'This usually takes under a minute.',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
