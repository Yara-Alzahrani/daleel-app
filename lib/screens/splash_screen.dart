import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';
import '../widgets/custom_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.isAuthenticated) {
      // User is logged in, navigate to home
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // User is not logged in, show welcome screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF006E51),
              const Color(0xFF006E51).withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const DaleelLogo(size: 150),
              const SizedBox(height: 40),
              Text(
                'DALEEL',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'دليل',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFE381),
                ),
              ),
              const SizedBox(height: 60),
              const CircularProgressIndicator(
                color: Color(0xFFFFE381),
              ),
            ],
          ),
        ),
      ),
    );
  }
}