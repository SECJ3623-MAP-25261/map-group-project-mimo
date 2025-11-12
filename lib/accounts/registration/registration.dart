import 'package:flutter/material.dart';
import 'dart:async';
import 'package:profile_managemenr/accounts/authentication/login.dart';
import 'package:profile_managemenr/main.dart';
import 'package:profile_managemenr/dbase/data.dart';
import 'package:profile_managemenr/models/user.dart';

// --- Theme Constants (Using dark colors with existing Teal accent) ---
const Color _accentColor = Color(0xFF2a9d8f); // Teal Accent
const Color _darkBackground = Color(0xFF1F2937);
const Color _cardBackground = Color(0xFF374151); // Form Card/Container background
const Color _inputFillColor = Color(0xFF111827); // Very dark input background
const Color _textColor = Colors.white;
const Color _hintColor = Colors.white60;
const Color _errorColor = Color(0xFFe76f51); // Coral/Orange for error

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
        brightness: Brightness.dark, // Set overall theme to dark
        scaffoldBackgroundColor: _darkBackground,
        primaryColor: _accentColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accentColor,
          brightness: Brightness.dark,
        ),
        // Apply dark theme input styling globally
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _inputFillColor,
          hintStyle: const TextStyle(color: _hintColor),
          labelStyle: const TextStyle(color: _hintColor, fontSize: 14),
          prefixIconColor: _hintColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4B5563), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4B5563), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accentColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _errorColor, width: 2),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: _textColor),
          bodySmall: TextStyle(color: _textColor),
          labelMedium: TextStyle(color: _hintColor, fontSize: 14),
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
  // ... (All state variables, controllers, and functions remain unchanged) ...
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Variables with initial values are kept
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

  // Dummy data list
  final List<String> _existingEmails = const [
    'john@example.com',
    'jane@example.com',
    'admin@test.com',
    'user@demo.com'
  ];

  // --- initState, dispose, _onEmailChanged, _onPasswordChanged, _isValidEmail, _checkEmailAvailability, _navigateToLogin, _submitForm remain unchanged ---
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
        MaterialPageRoute(builder: (context) => const CampusClosetScreen()), 
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
    } else if (!_termsAccepted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the Terms & Conditions to register.'),
          backgroundColor: _errorColor,
        ),
      );
    }
  }
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Note: The dark gradient background is removed in favor of a flat dark theme
    return Scaffold(
      backgroundColor: _darkBackground, // Use flat dark background
      body: SafeArea(
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
    );
  }

  Widget _buildRegistrationCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBackground, // Dark card background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
      children: const [
        Text(
          'Account Registration',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _textColor, // White text
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Create your account to start renting and listing!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _hintColor, // Muted white
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleChangeInfo() {
    return Container(
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.2), // Darker, less blinding info box
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _accentColor.withOpacity(0.5),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, size: 18, color: _accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Flexible Role Selection',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'You start as a renter, but can easily switch to a lister role anytime in your profile settings.',
                  style: TextStyle(
                    fontSize: 13,
                    color: _hintColor,
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
        color: _darkBackground.withOpacity(0.7), // Use dark background for contrast
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B5563)),
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
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Limited features (viewing only) available.',
                  style: TextStyle(
                    fontSize: 13,
                    color: _hintColor,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isGuestMode = !_isGuestMode;
                _successMessage = ''; // Clear success message if toggling guest mode
              });
            },
            child: Container(
              width: 48,
              height: 24,
              decoration: BoxDecoration(
                color: _isGuestMode
                    ? _accentColor
                    : const Color(0xFF4B5563), // Darker off state
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
                    color: _textColor, // White dot
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
        color: const Color(0xFF4CAF50).withOpacity(0.2), // Green success background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.5)),
      ),
      child: Text(
        _successMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF4CAF50), // Green text
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildForm() {
    // Opacity and IgnorePointer logic remains the same
    return Opacity(
      opacity: _isGuestMode ? 0.4 : 1.0,
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
            color: _textColor, // White label text
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: _textColor), // Input text color
          // Decoration inherits from MaterialApp theme
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
            color: _textColor, // White label text
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: _textColor), // Input text color
          validator: (value) {
            if (value == null || !_isValidEmail(value)) {
              return 'Please enter a valid email';
            }
            // Check for existence only if validation is otherwise fine
            if (_emailStatus == 'taken' && value.toLowerCase() == _emailController.text.toLowerCase()) {
              return 'Email already exists';
            }
            return null;
          },
        ),
        const SizedBox(height: 4),
        if (_emailStatus.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                if (_emailStatus == 'checking')
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: _accentColor,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  _emailStatus == 'checking'
                      ? 'Checking availability...'
                      : _emailStatus == 'taken'
                          ? '✗ Email already exists'
                          : '✓ Email available',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _emailStatus == 'checking'
                        ? _accentColor
                        : _emailStatus == 'taken'
                            ? _errorColor
                            : const Color(0xFF4CAF50),
                  ),
                ),
              ],
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
            color: _textColor, // White label text
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_passwordVisible,
          style: const TextStyle(color: _textColor),
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
                  color: _accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
            fontWeight: FontWeight.w500,
            color: _passwordStrength == 0 ? _hintColor : _passwordStrengthColor,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: const Color(0xFF4B5563), // Darker track
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
          width: 24, // Fix width for consistent alignment
          height: 24,
          child: Checkbox(
            value: _termsAccepted,
            onChanged: (value) {
              setState(() {
                _termsAccepted = value ?? false;
              });
            },
            activeColor: _accentColor,
            checkColor: _inputFillColor, // Dark checkmark
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: const BorderSide(color: _hintColor, width: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _termsAccepted = !_termsAccepted;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0), // Adjust for checkbox height
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: _hintColor,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: TextStyle(color: _accentColor, fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(color: _accentColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
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
        onPressed: (_isSubmitting || (_isGuestMode == false && _termsAccepted == false)) ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: _textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
          disabledBackgroundColor: const Color(0xFF4B5563), // Darker disabled state
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_textColor),
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

  Widget _buildLoginButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(
            color: _hintColor, // Muted white
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
              color: _accentColor, // Teal accent
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}