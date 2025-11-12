import 'package:flutter/material.dart';
import 'dart:async';
<<<<<<< HEAD
import 'package:campus_closet/accounts/authentication/login.dart';
import 'package:campus_closet/main.dart';
=======
import 'package:profile_managemenr/accounts/authentication/login.dart';
import 'package:profile_managemenr/main.dart';
import 'package:profile_managemenr/dbase/data.dart';
import 'package:profile_managemenr/models/user.dart';

>>>>>>> 0f565fb517835cc6ce3ac3f2029780fc16004f04

void main() {
  runApp(const RegistrationApp());
}

class RegistrationApp extends StatelessWidget {
  const RegistrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Account Registration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0f0f23),
      ),
      home: const RegistrationScreen(),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _userType = 'rentee';
  bool _isGuestMode = false;
  bool _passwordVisible = false;
  bool _termsAccepted = false;
  String _emailStatus = '';
  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = 'Password strength';
  Color _passwordStrengthColor = Colors.transparent;
  String _successMessage = '';
  bool _isSubmitting = false;
  Timer? _emailCheckTimer;

  final List<String> _existingEmails = [
    'john@example.com',
    'jane@example.com',
    'admin@test.com',
    'user@demo.com'
  ];

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailCheckTimer?.cancel();
    super.dispose();
  }

  void _onEmailChanged() {
    _emailCheckTimer?.cancel();
    final email = _emailController.text.trim();

    if (email.isNotEmpty && _isValidEmail(email)) {
      setState(() {
        _emailStatus = 'checking';
      });

      _emailCheckTimer = Timer(const Duration(milliseconds: 500), () {
        _checkEmailAvailability(email);
      });
    } else {
      setState(() {
        _emailStatus = '';
      });
    }
  }

  void _onPasswordChanged() {
    final password = _passwordController.text;
    int strength = 0;

    if (password.length >= 8) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) strength++;

    setState(() {
      _passwordStrength = strength / 5;

      if (strength == 0) {
        _passwordStrengthLabel = 'Password strength';
        _passwordStrengthColor = Colors.transparent;
      } else if (strength <= 2) {
        _passwordStrengthLabel = 'Weak password';
        _passwordStrengthColor = const Color(0xFFff4d4f);
      } else if (strength == 3) {
        _passwordStrengthLabel = 'Fair password';
        _passwordStrengthColor = const Color(0xFFfaad14);
      } else if (strength == 4) {
        _passwordStrengthLabel = 'Good password';
        _passwordStrengthColor = const Color(0xFF52c41a);
      } else {
        _passwordStrengthLabel = 'Strong password';
        _passwordStrengthColor = const Color(0xFF4096ff);
      }
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  void _checkEmailAvailability(String email) {
    setState(() {
      if (_existingEmails.contains(email.toLowerCase())) {
        _emailStatus = 'taken';
      } else {
        _emailStatus = 'available';
      }
    });
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );

  }

void _submitForm() async {
  if (_isGuestMode) {
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyApp()), 
    );
    return;
  }

  
  if (_formKey.currentState!.validate() && _termsAccepted) {
    setState(() {
      _isSubmitting = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
  // Create new user
  final newUser = User(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: _nameController.text.trim(),
    email: _emailController.text.trim(),
    phone: _phoneController.text.trim(),
    profileImages: '',
  );

  // Add to dummy database
  dummyUsers.add(newUser);

  _successMessage =
      'Registration successful! Welcome ${newUser.name}. You can now login.';
  _isSubmitting = false;
});


    
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0f0f23),
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildRegistrationCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationCard() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1a1a2e).withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color(0xFF4096ff).withOpacity(0.2),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
      ],
    ),
    padding: const EdgeInsets.all(30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 30),
        _buildRoleChangeInfo(),
        const SizedBox(height: 25),
        _buildGuestOption(),
        const SizedBox(height: 20),
        if (_successMessage.isNotEmpty) _buildSuccessMessage(),
        // Form is now WITHOUT the submit button
        _buildForm(),
        const SizedBox(height: 20),
        // 👇 Submit button is OUTSIDE the IgnorePointer
        _buildSubmitButton(),
        const SizedBox(height: 20),
        _buildLoginButton(),
      ],
    ),
  );
}

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF4096ff), Color(0xFF69c0ff)],
          ).createShader(bounds),
          child: const Text(
            'Account Registration',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Create your account',
          style: TextStyle(
            color: Color(0xFFa0a0a0),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleChangeInfo() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4096ff).withOpacity(0.1),
        border: Border.all(
          color: const Color(0xFF4096ff).withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ℹ️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Flexible Role Selection',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4096ff),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'You can change your role anytime after registration in your profile settings',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFa0a0a0),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestOption() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0f0f23).withOpacity(0.6),
        border: Border.all(
          color: const Color(0xFF4096ff).withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Continue as Guest',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Limited features available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFa0a0a0),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isGuestMode = !_isGuestMode;
              });
            },
            child: Container(
              width: 48,
              height: 24,
              decoration: BoxDecoration(
                color: _isGuestMode
                    ? const Color(0xFF4096ff)
                    : const Color(0xFF4096ff).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: _isGuestMode ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF52c41a).withOpacity(0.1),
        border: Border.all(
          color: const Color(0xFF52c41a).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _successMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF52c41a),
        ),
      ),
    );
  }

  Widget _buildForm() {
  return Opacity(
    opacity: _isGuestMode ? 0.6 : 1.0,
    child: IgnorePointer(
      ignoring: _isGuestMode,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildEmailField(),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'Enter your phone number',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                }
                final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                if (!RegExp(r'^[\+]?[1-9][\d]{0,15}$').hasMatch(cleaned)) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Confirm your password',
              obscureText: true,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 25),
            _buildTermsCheckbox(),
            // ❌ NO _buildSubmitButton() here
          ],
        ),
      ),
    ),
  );
}

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFFe0e0e0),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF666666)),
            filled: true,
            fillColor: const Color(0xFF0f0f23).withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF4096ff).withOpacity(0.3),
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF4096ff).withOpacity(0.3),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4096ff),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFff4d4f),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Address',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFFe0e0e0),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || !_isValidEmail(value)) {
              return 'Please enter a valid email';
            }
            if (_existingEmails.contains(value.toLowerCase())) {
              return 'Email already exists';
            }
            return null;
          },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: const TextStyle(color: Color(0xFF666666)),
            filled: true,
            fillColor: const Color(0xFF0f0f23).withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF4096ff).withOpacity(0.3),
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF4096ff).withOpacity(0.3),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4096ff),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 4),
        if (_emailStatus.isNotEmpty)
          Text(
            _emailStatus == 'checking'
                ? 'Checking availability...'
                : _emailStatus == 'taken'
                    ? '✗ Email already exists'
                    : '✓ Email available',
            style: TextStyle(
              fontSize: 12,
              color: _emailStatus == 'checking'
                  ? const Color(0xFF4096ff)
                  : _emailStatus == 'taken'
                      ? const Color(0xFFff4d4f)
                      : const Color(0xFF52c41a),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFFe0e0e0),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_passwordVisible,
          validator: (value) {
            if (value == null || value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Create a strong password',
            hintStyle: const TextStyle(color: Color(0xFF666666)),
            filled: true,
            fillColor: const Color(0xFF0f0f23).withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF4096ff).withOpacity(0.3),
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF4096ff).withOpacity(0.3),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4096ff),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: IconButton(
              icon: Text(
                _passwordVisible ? 'Hide' : 'Show',
                style: const TextStyle(
                  color: Color(0xFF4096ff),
                  fontSize: 14,
                ),
              ),
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _passwordStrengthLabel,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFa0a0a0),
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: const Color(0xFF4096ff).withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: _termsAccepted,
            onChanged: (value) {
              setState(() {
                _termsAccepted = value ?? false;
              });
            },
            activeColor: const Color(0xFF4096ff),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _termsAccepted = !_termsAccepted;
              });
            },
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFa0a0a0),
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: TextStyle(color: Color(0xFF4096ff)),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(color: Color(0xFF4096ff)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4096ff), Color(0xFF69c0ff)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4096ff).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : _submitForm,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isGuestMode ? 'Continue as Guest' : 'Create Account',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // Login button widget
  Widget _buildLoginButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(
            color: Color(0xFFa0a0a0),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: _navigateToLogin,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Login',
            style: TextStyle(
              color: Color(0xFF4096ff),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}