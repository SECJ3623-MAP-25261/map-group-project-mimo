import 'package:flutter/material.dart';
import 'dart:async';
import 'package:profile_managemenr/accounts/authentication/login.dart';
import 'package:profile_managemenr/main.dart';

import '../../constants/app_colors.dart';
import 'validators.dart';
import 'password_strength.dart';
import 'registration_widget.dart';
import 'form_fields.dart';
import '/services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _authService = AuthService(); // Instance variable
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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

    if (email.isNotEmpty && Validators.isValidEmail(email)) {
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
    final strengthData = PasswordStrengthCalculator.calculate(_passwordController.text);
    setState(() {
      _passwordStrength = strengthData.strength;
      _passwordStrengthLabel = strengthData.label;
      _passwordStrengthColor = strengthData.color;
    });
  }

  // Updated to use Firebase
  Future<void> _checkEmailAvailability(String email) async {
    try {
      final exists = await _authService.checkEmailExists(email);
      if (mounted) {
        setState(() {
          _emailStatus = exists ? 'taken' : 'available';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _emailStatus = '';
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Updated to use Firebase
  Future<void> _submitForm() async {
    // Guest mode handling
    if (_isGuestMode) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CampusClosetScreen()),
      );
      return;
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the Terms & Conditions to register.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    // Start registration
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Register user with Firebase
      final user = await _authService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(), // Add phone to auth service
      );

      if (user != null && mounted) {
        setState(() {
          _successMessage = 'Registration successful! Welcome ${_nameController.text}. You can now login.';
          _isSubmitting = false;
        });

        // Optional: Auto-navigate to login after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _navigateToLogin();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
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
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.lightBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RegistrationHeader(),
          const SizedBox(height: 24),
          const RoleChangeInfo(),
          const SizedBox(height: 20),
          GuestModeToggle(
            isGuestMode: _isGuestMode,
            onToggle: () {
              setState(() {
                _isGuestMode = !_isGuestMode;
                _successMessage = '';
              });
            },
          ),
          const SizedBox(height: 20),
          if (_successMessage.isNotEmpty) 
            SuccessMessage(message: _successMessage),
          if (_successMessage.isNotEmpty) 
            const SizedBox(height: 20),
          _buildForm(),
          const SizedBox(height: 20),
          _buildSubmitButton(),
          const SizedBox(height: 16),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Opacity(
      opacity: _isGuestMode ? 0.4 : 1.0,
      child: IgnorePointer(
        ignoring: _isGuestMode,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                validator: Validators.validateName,
              ),
              const SizedBox(height: 20),
              EmailField(
                controller: _emailController,
                emailStatus: _emailStatus,
                validator: (value) => Validators.validateEmail(
                  value,
                  emailStatus: _emailStatus,
                ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
              ),
              const SizedBox(height: 20),
              PasswordField(
                controller: _passwordController,
                passwordVisible: _passwordVisible,
                onToggleVisibility: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
                passwordStrength: _passwordStrength,
                passwordStrengthLabel: _passwordStrengthLabel,
                passwordStrengthColor: _passwordStrengthColor,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Confirm your password',
                obscureText: true,
                validator: (value) => Validators.validateConfirmPassword(
                  value,
                  _passwordController.text,
                ),
              ),
              const SizedBox(height: 25),
              TermsCheckbox(
                termsAccepted: _termsAccepted,
                onChanged: (value) {
                  setState(() {
                    _termsAccepted = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isSubmitting || (!_isGuestMode && !_termsAccepted))
            ? null
            : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentColor,
          foregroundColor: AppColors.lightTextColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
          disabledBackgroundColor: AppColors.lightBorderColor,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkTextColor),
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
            color: AppColors.lightHintColor,
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
              color: AppColors.accentColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}