import 'package:flutter/material.dart';
import 'package:profile_managemenr/accounts/authentication/login.dart';
import 'package:profile_managemenr/home/screens/campus_closet_screen.dart';

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
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isGuestMode = false;
  bool _passwordVisible = false;
  bool _termsAccepted = false;

  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = 'Password strength';
  Color _passwordStrengthColor = Colors.transparent;

  String _successMessage = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    final strengthData =
        PasswordStrengthCalculator.calculate(_passwordController.text);
    setState(() {
      _passwordStrength = strengthData.strength;
      _passwordStrengthLabel = strengthData.label;
      _passwordStrengthColor = strengthData.color;
    });
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _submitForm() async {
    if (_isGuestMode) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CampusClosetScreen()),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the Terms & Conditions to register.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = await _authService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (user != null && mounted) {
        setState(() {
          _successMessage =
              'Registration successful! Welcome ${_nameController.text}. You can now login.';
          _isSubmitting = false;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _navigateToLogin();
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      String message = 'Registration failed';

      if (e.toString().contains('email-already-in-use')) {
        message = 'This email is already registered';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
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
      padding: const EdgeInsets.all(30),
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
          if (_successMessage.isNotEmpty) ...[
            SuccessMessage(message: _successMessage),
            const SizedBox(height: 20),
          ],
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
                emailStatus: '',
                validator: Validators.validateEmail,
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
                onToggleVisibility: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
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
                validator: (value) =>
                    Validators.validateConfirmPassword(
                        value, _passwordController.text),
              ),
              const SizedBox(height: 25),
              TermsCheckbox(
                termsAccepted: _termsAccepted,
                onChanged: (value) =>
                    setState(() => _termsAccepted = value),
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
        onPressed:
            (_isSubmitting || (!_isGuestMode && !_termsAccepted))
                ? null
                : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(strokeWidth: 2)
            : Text(_isGuestMode ? 'Continue as Guest' : 'Create Account'),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? '),
        TextButton(
          onPressed: _navigateToLogin,
          child: const Text('Login'),
        ),
      ],
    );
  }
}
