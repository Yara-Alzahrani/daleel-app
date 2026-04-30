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
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  StreamSubscription<DocumentSnapshot>? _tripSubscription;

  final List<String> _loadingMessages = [
    'Analyzing your preferences...',
    'Discovering the best spots in your city...',
    'Crafting your personalized plan...',
    'Adding local tips and recommendations...',
    'Almost ready!',
  ];
  int _messageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();

    // Animation ترتفع من الأسفل للأعلى وترجع بشكل مستمر
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: -30).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() =>
            _messageIndex = (_messageIndex + 1) % _loadingMessages.length);
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
        Navigator.of(context)
            .pushReplacementNamed('/itinerary', arguments: widget.tripId);
      } else if (status == 'failed') {
        _tripSubscription?.cancel();
        _showErrorDialog(snapshot.data()?['errorMessage'] as String? ??
            'Something went wrong. Please try again.');
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
              Navigator.of(context).pop();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/home', (route) => false);
            },
            child: const Text('Go Home',
                style: TextStyle(color: Color(0xFF006E51))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
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
              // الشعار مع animation ترتفع من الأسفل للأعلى
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/images/daleelfree.png',
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 48),

              const Text(
                'Creating Your Plan',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006E51)),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _loadingMessages[_messageIndex],
                  key: ValueKey(_messageIndex),
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                          : const Color(0xFFA384DA).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 64),

              Text('This usually takes under a minute.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400])),
            ],
          ),
        ),
      ),
    );
  }
}
