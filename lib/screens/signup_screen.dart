import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedGender = '';
  String _selectedNationality = '';
  String _selectedPhonePrefix = '+966';
  bool _isLoading = false;

  final List<Map<String, String>> _phonePrefixes = [
    {'code': '+966', 'country': 'Saudi Arabia'},
    {'code': '+971', 'country': 'UAE'},
    {'code': '+965', 'country': 'Kuwait'},
    {'code': '+974', 'country': 'Qatar'},
    {'code': '+973', 'country': 'Bahrain'},
    {'code': '+968', 'country': 'Oman'},
    {'code': '+20', 'country': 'Egypt'},
    {'code': '+962', 'country': 'Jordan'},
    {'code': '+961', 'country': 'Lebanon'},
    {'code': '+963', 'country': 'Syria'},
    {'code': '+964', 'country': 'Iraq'},
    {'code': '+967', 'country': 'Yemen'},
    {'code': '+970', 'country': 'Palestine'},
    {'code': '+212', 'country': 'Morocco'},
    {'code': '+213', 'country': 'Algeria'},
    {'code': '+216', 'country': 'Tunisia'},
    {'code': '+218', 'country': 'Libya'},
    {'code': '+249', 'country': 'Sudan'},
    {'code': '+1', 'country': 'USA/Canada'},
    {'code': '+44', 'country': 'UK'},
  ];

  final List<String> _genders = ['Male', 'Female'];
  final List<String> _nationalities = [
    'Saudi Arabian',
    'Emirati',
    'Kuwaiti',
    'Qatari',
    'Bahraini',
    'Omani',
    'Egyptian',
    'Jordanian',
    'Lebanese',
    'Syrian',
    'Iraqi',
    'Yemeni',
    'Palestinian',
    'Moroccan',
    'Algerian',
    'Tunisian',
    'Libyan',
    'Sudanese',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showPhonePrefixBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Country Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _phonePrefixes.length,
                  itemBuilder: (context, index) {
                    final prefix = _phonePrefixes[index];
                    return ListTile(
                      title: Text('${prefix['code']} (${prefix['country']})'),
                      leading: Text(
                        prefix['code']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006E51),
                        ),
                      ),
                      onTap: () {
                        setState(() => _selectedPhonePrefix = prefix['code']!);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBottomSheet({
    required String title,
    required List<String> items,
    required Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(items[index]),
                      onTap: () {
                        onSelect(items[index]);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gender'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedNationality.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your nationality'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      print('Starting sign up process...');
      
      // Step 1: Create Firebase Auth account
      String? error = await authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (error != null) {
        throw Exception(error);
      }

      print('User created successfully, saving user info...');

      // Step 2: Wait a moment for Firebase to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 3: Save user info to Firestore
      error = await authService.saveUserInfo(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: '$_selectedPhonePrefix${_phoneController.text}',
        gender: _selectedGender,
        nationality: _selectedNationality,
      );

      if (error != null) {
        throw Exception(error);
      }

      print('User info saved successfully');

      setState(() => _isLoading = false);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Color(0xFF006E51),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to home after short delay
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      print('Sign up error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign up failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'Personal Info.',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Custom Logo Image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFA384DA),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/daleel_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if image not found - show icon
                        return Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey[400],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    hintStyle: TextStyle(color: Colors.grey[400]),
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
                      borderSide: const BorderSide(color: Color(0xFF006E51), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.grey[400]),
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
                      borderSide: const BorderSide(color: Color(0xFF006E51), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Field
                Row(
                  children: [
                    GestureDetector(
                      onTap: _showPhonePrefixBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFA384DA), width: 2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _selectedPhonePrefix,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFFA384DA),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '5xxxxxxxxxx',
                          hintStyle: TextStyle(color: Colors.grey[400]),
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
                            borderSide: const BorderSide(color: Color(0xFF006E51), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (value.length < 8) {
                            return 'Phone number too short';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Gender and Nationality Row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _showBottomSheet(
                            title: 'Select Gender',
                            items: _genders,
                            onSelect: (value) {
                              setState(() => _selectedGender = value);
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFA384DA), width: 2),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            _selectedGender.isEmpty ? 'Gender' : _selectedGender,
                            style: TextStyle(
                              color: _selectedGender.isEmpty ? Colors.grey[400] : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _showBottomSheet(
                            title: 'Select Nationality',
                            items: _nationalities,
                            onSelect: (value) {
                              setState(() => _selectedNationality = value);
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFA384DA), width: 2),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            _selectedNationality.isEmpty ? 'Nationality' : _selectedNationality,
                            style: TextStyle(
                              color: _selectedNationality.isEmpty ? Colors.grey[400] : Colors.black,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: Colors.grey[400]),
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
                      borderSide: const BorderSide(color: Color(0xFF006E51), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA384DA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Next'),
                  ),
                ),
                const SizedBox(height: 20),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color(0xFF006E51),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}