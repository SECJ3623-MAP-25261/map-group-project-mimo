import 'package:flutter/material.dart';
import 'dart:async';
import 'package:profile_managemenr/accounts/authentication/login.dart';
import 'package:profile_managemenr/main.dart';
import 'package:profile_managemenr/dbase/data.dart';
import 'package:profile_managemenr/models/user.dart';

import '../../constants/app_colors.dart';
import 'validators.dart';
import 'password_strength.dart';
import 'registration_widget.dart';
import 'form_fields.dart';

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

  //final String _userType = 'rentee';
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

  final List<String> _existingEmails = const [
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
        final newUser = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          profileImages: '',
        );

        dummyUsers.add(newUser);

        _successMessage =
            'Registration successful! Welcome ${newUser.name}. You can now login.';
        _isSubmitting = false;
      });
    } else if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the Terms & Conditions to register.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
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
        onPressed: (_isSubmitting || (_isGuestMode == false && _termsAccepted == false))
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