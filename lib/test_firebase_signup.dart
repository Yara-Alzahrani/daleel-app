import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TestFirebaseApp());
}

class TestFirebaseApp extends StatelessWidget {
  const TestFirebaseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Test Firebase Signup',
      home: TestFirebaseScreen(),
    );
  }
}

class TestFirebaseScreen extends StatefulWidget {
  const TestFirebaseScreen({Key? key}) : super(key: key);

  @override
  State<TestFirebaseScreen> createState() => _TestFirebaseScreenState();
}

class _TestFirebaseScreenState extends State<TestFirebaseScreen> {
  final _emailController = TextEditingController(text: 'test@test.com');
  final _passwordController = TextEditingController(text: 'test123456');
  final _nameController = TextEditingController(text: 'Test User');
  String _status = 'Ready to test';
  bool _isLoading = false;

  Future<void> _testSignUp() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firebase signup...';
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim();

      // Step 1: Check Firebase connection
      setState(() => _status = 'Step 1: Checking Firebase connection...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      final app = Firebase.app();
      print('✓ Firebase app: ${app.name}');

      // Step 2: Create user with email/password
      setState(() => _status = 'Step 2: Creating user account...');
      await Future.delayed(const Duration(milliseconds: 500));

      final auth = FirebaseAuth.instance;
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✓ User created: ${userCredential.user?.uid}');
      print('✓ User email: ${userCredential.user?.email}');

      // Step 3: Save to Firestore
      setState(() => _status = 'Step 3: Saving user info to Firestore...');
      await Future.delayed(const Duration(milliseconds: 500));

      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': name,
        'email': email,
        'phone': '+966512345678',
        'gender': 'Male',
        'nationality': 'Saudi Arabian',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✓ User info saved to Firestore');

      // Step 4: Verify data was saved
      setState(() => _status = 'Step 4: Verifying data...');
      await Future.delayed(const Duration(milliseconds: 500));

      final doc = await firestore.collection('users').doc(userCredential.user?.uid).get();
      print('✓ Data retrieved: ${doc.data()}');

      setState(() => _status = '✅ SUCCESS! All steps completed.');

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Success!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User ID: ${userCredential.user?.uid}'),
                const SizedBox(height: 8),
                Text('Email: ${userCredential.user?.email}'),
                const SizedBox(height: 8),
                const Text('Firestore data saved successfully!'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      // Clean up - delete test user
      await Future.delayed(const Duration(seconds: 2));
      await userCredential.user?.delete();
      print('✓ Test user deleted');

    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      setState(() => _status = '❌ Auth Error: ${e.code}\n${e.message}');
    } on FirebaseException catch (e) {
      print('❌ Firebase Error: ${e.code} - ${e.message}');
      setState(() => _status = '❌ Firestore Error: ${e.code}\n${e.message}');
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('Stack trace: $stackTrace');
      setState(() => _status = '❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firebase Signup'),
        backgroundColor: const Color(0xFF006E51),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Firebase Signup Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Test Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Test Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Test Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _testSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA384DA),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Test Signup Process',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}