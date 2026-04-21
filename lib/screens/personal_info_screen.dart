import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_widgets.dart';

class PersonalInfoScreen extends StatefulWidget {
  final String? email;
  final String? phoneNumber;

  const PersonalInfoScreen({
    Key? key,
    this.email,
    this.phoneNumber,
  }) : super(key: key);

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedGender = '';
  String _selectedNationality = '';
  bool _isLoading = false;

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
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
    if (widget.phoneNumber != null) {
      _phoneController.text = widget.phoneNumber!.replaceFirst('+966', '');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveInfo() async {
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

    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.saveUserInfo(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: '+966${_phoneController.text}',
      gender: _selectedGender,
      nationality: _selectedNationality,
    );

    setState(() => _isLoading = false);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    } else if (mounted) {
      // Navigate to home screen
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
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
                // Profile Picture Placeholder
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFA384DA),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  hint: 'Name',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  hint: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFA384DA), width: 2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Text(
                        '+966',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        hint: '5xxxxxxxxxx',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (value.length != 9) {
                            return 'Phone must be 9 digits';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 40),
                CustomButton(
                  text: 'Next',
                  onPressed: _handleSaveInfo,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}