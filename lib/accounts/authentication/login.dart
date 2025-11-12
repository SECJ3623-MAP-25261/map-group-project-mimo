import 'package:flutter/material.dart';
import 'forget_password.dart';
import 'package:profile_managemenr/accounts/registration/registration.dart';
// Assuming you have a home screen or dashboard to navigate to after login
// import 'package:profile_managemenr/home_screen.dart'; 


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _passwordVisible = false;
  bool _isLoading = false;

  // Consistent theme colors
  static const Color _primaryAccentColor = Color(0xFF3B82F6); // Vibrant Blue
  static const Color _darkBackground = Color(0xFF1F2937); // Slightly lighter dark background
  static const Color _cardBackground = Color(0xFF374151); // Input field background
  static const Color _textColor = Colors.white;
  static const Color _hintColor = Colors.white54;
  static const Color _borderColor = Color(0xFF4B5563);

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationApp()),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate network request
      await Future.delayed(const Duration(seconds: 2));

      // Placeholder for successful login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Successful! Welcome back.'),
          backgroundColor: _primaryAccentColor,
          duration: Duration(seconds: 2),
        ),
      );

      

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      body: Center( // Center the login form on the screen
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400), // Max width for the card
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: _cardBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Keep column size minimal
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _primaryAccentColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Login to your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _hintColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email or Phone Input
                  TextFormField(
                    controller: _emailPhoneController,
                    style: const TextStyle(color: _textColor),
                    decoration: InputDecoration(
                      labelText: 'Email or Phone',
                      labelStyle: const TextStyle(color: _hintColor),
                      prefixIcon: const Icon(Icons.person_outline, color: _primaryAccentColor),
                      filled: true,
                      fillColor: _darkBackground.withOpacity(0.5), // Use a slightly darker fill
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryAccentColor, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email or phone number.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    style: const TextStyle(color: _textColor),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: _hintColor),
                      prefixIcon: const Icon(Icons.lock_outline, color: _primaryAccentColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility_off : Icons.visibility,
                          color: _hintColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: _darkBackground.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryAccentColor, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                            activeColor: _primaryAccentColor,
                            checkColor: _textColor,
                            side: const BorderSide(color: _hintColor, width: 1.5),
                          ),
                          const Text(
                            'Remember me',
                            style: TextStyle(color: _hintColor, fontSize: 13),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _navigateToForgotPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: _primaryAccentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryAccentColor,
                      foregroundColor: _textColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: _textColor,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Or divider (Optional, but adds to modern look)
                  Row(
                    children: const [
                      Expanded(child: Divider(color: _hintColor)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("OR", style: TextStyle(color: _hintColor, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: _hintColor)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Register Button (using _buildRegisterButton helper)
                  _buildRegisterButton(),
                  const SizedBox(height: 40),

                  // Footer Text
                  const Text(
                    'Campus Closet © 2025',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(
            color: _hintColor,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: _navigateToRegister,
          child: const Text(
            'Sign Up', // Changed "Register" to "Sign Up" for consistency
            style: TextStyle(
              color: _primaryAccentColor, // Use vibrant accent color
              fontSize: 14,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: _primaryAccentColor,
            ),
          ),
        ),
      ],
    );
  }
}