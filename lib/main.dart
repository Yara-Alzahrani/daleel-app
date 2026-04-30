import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/create_plan_screen.dart';
import 'screens/trip_loading_screen.dart';
import 'screens/itinerary_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/account_settings_screen.dart';
import 'screens/past_plans_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const DaleelApp());
}

class DaleelApp extends StatelessWidget {
  const DaleelApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Daleel',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF006E51),
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF006E51),
            primary: const Color(0xFF006E51),
            secondary: const Color(0xFFA384DA),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: Color(0xFFA384DA), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: Color(0xFFA384DA), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: Color(0xFFA384DA), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA384DA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/create-plan': (context) => const CreatePlanScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/account-settings': (context) => const AccountSettingsScreen(),
          '/past-plans': (context) => const PastPlansScreen(),
          '/trip-loading': (context) {
            final tripId = ModalRoute.of(context)!.settings.arguments as String;
            return TripLoadingScreen(tripId: tripId);
          },
          '/itinerary': (context) {
            final tripId = ModalRoute.of(context)!.settings.arguments as String;
            return ItineraryScreen(tripId: tripId);
          },
        },
      ),
    );
  }
}