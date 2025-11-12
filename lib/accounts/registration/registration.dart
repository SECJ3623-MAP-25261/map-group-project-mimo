import 'package:flutter/material.dart';
import 'dart:async';
import 'package:profile_managemenr/accounts/authentication/login.dart';
import 'package:profile_managemenr/main.dart';
import 'package:profile_managemenr/dbase/data.dart';
import 'package:profile_managemenr/models/user.dart';

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
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB), // Very light gray
        primaryColor: const Color(0xFF2a9d8f), // Teal - professional & cheerful
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2a9d8f),
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F3F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD0D5DD), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD0D5DD), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2a9d8f), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFe76f51), width: 2),
          ),
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textTheme: TextTheme(
          bodyMedium: const TextStyle(color: Color(0xFF374151)),
          labelMedium: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
        ),
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

  final String _userType = 'rentee';
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF000000).withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    padding: const EdgeInsets.all(30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildRoleChangeInfo(),
        const SizedBox(height: 20),
        _buildGuestOption(),
        const SizedBox(height: 20),
        if (_successMessage.isNotEmpty) _buildSuccessMessage(),
        _buildForm(),
        const SizedBox(height: 20),
        _buildSubmitButton(),
        const SizedBox(height: 16),
        _buildLoginButton(),
      ],
    ),
  );
}

  Widget _buildHeader() {
  return Column(
    children: [
      Text(
        'Account Registration',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF111827), // Near-black for readability
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Create your account',
        style: TextStyle(
          color: Color(0xFF6B7280), // Muted gray
          fontSize: 16,
        ),
      ),
    ],
  );
}

Widget _buildRoleChangeInfo() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF2a9d8f).withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFF2a9d8f).withOpacity(0.3),
      ),
    ),
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info, size: 18, color: Color(0xFF2a9d8f)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Flexible Role Selection',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2a9d8f),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'You can change your role anytime after registration in your profile settings',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
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
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFD1D5DB)),
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
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Limited features available',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
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
                  ? const Color(0xFF2a9d8f)
                  : const Color(0xFFD1D5DB),
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
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF4CAF50).withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
    ),
    child: Text(
      _successMessage,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFF2E7D32),
        fontWeight: FontWeight.w500,
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
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        // Let the global theme handle style & decoration
      ),
    ],
  );
}

Widget _buildEmailField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Email Address',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
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
                ? const Color(0xFF2a9d8f) // teal
                : _emailStatus == 'taken'
                    ? const Color(0xFFe76f51) // coral (error)
                    : const Color(0xFF4CAF50), // green (success)
          ),
        ),
    ],
  );
}

Widget _buildPasswordField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Password',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
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
        decoration: InputDecoration(
          suffixIcon: IconButton(
            icon: Text(
              _passwordVisible ? 'Hide' : 'Show',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
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
        style: TextStyle(
          fontSize: 12,
          color: _passwordStrength == 0
              ? const Color(0xFF9CA3AF)
              : _passwordStrengthColor,
        ),
      ),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: _passwordStrength,
          backgroundColor: const Color(0xFFE5E7EB),
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
      Checkbox(
        value: _termsAccepted,
        onChanged: (value) {
          setState(() {
            _termsAccepted = value ?? false;
          });
        },
        activeColor: const Color(0xFF2a9d8f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _termsAccepted = !_termsAccepted;
            });
          },
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms & Conditions',
                  style: const TextStyle(color: Color(0xFF2a9d8f), fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(color: Color(0xFF2a9d8f), fontWeight: FontWeight.w600),
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
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _isSubmitting ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2a9d8f),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        disabledBackgroundColor: const Color(0xFF9CA3AF),
      ),
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
          color: Color(0xFF4B5563),
          fontSize: 14,
        ),
      ),
      TextButton(
        onPressed: _navigateToLogin,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Login',
          style: TextStyle(
            color: Color(0xFF2a9d8f),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
}