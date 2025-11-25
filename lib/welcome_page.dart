import 'package:flutter/material.dart';
import 'package:profile_managemenr/accounts/authentication/login.dart';
import 'package:profile_managemenr/accounts/registration/registration_app.dart';
import 'package:profile_managemenr/main.dart';
import '../constants/app_colors.dart';
//import '../constants/app_theme.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const MyApp());
}


class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _mainController;
  late AnimationController _shimmerController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _mainOpacity;
  late Animation<Offset> _mainSlide;
  late Animation<double> _shimmerAnimation;
  
  bool _showWelcome = true;

  // Configuration
  final String logoUrl = "lib/widgets/CampusClosetLogo.png";
  final String appName = "Campus Closet";
  final String welcomeMessage = "Welcome Back!";
  final String tagline = "Your digital companion";

  @override
  void initState() {
    super.initState();
    
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_logoController);
    
    _logoRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    
    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    
    // Main screen animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _mainOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );
    
    _mainSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOut));
    
    // Shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _shimmerAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.2, end: 0.4), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.4, end: 0.2), weight: 50),
    ]).animate(_shimmerController);
    
    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    _logoController.forward();
    _shimmerController.repeat();
    
    await Future.delayed(const Duration(milliseconds: 1000));
    _textController.forward();
    
    await Future.delayed(const Duration(milliseconds: 2000));
    setState(() => _showWelcome = false);
    _mainController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _mainController.dispose();
    _shimmerController.dispose();
    super.dispose();
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
              AppColors.accentColor,
              Color(0xFF1e8079), // Darker shade of accent
            ],
          ),
        ),
        child: Stack(
          children: [
            // Main authentication screen
            Center(
              child: SlideTransition(
                position: _mainSlide,
                child: FadeTransition(
                  opacity: _mainOpacity,
                  child: _buildMainScreen(),
                ),
              ),
            ),
            
            // Welcome screen overlay
            if (_showWelcome)
              AnimatedOpacity(
                opacity: _showWelcome ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: Container(
                  color: AppColors.accentColor,
                  child: Center(child: _buildWelcomeContent()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo with animations
        AnimatedBuilder(
          animation: Listenable.merge([_logoController, _shimmerController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _logoScale.value,
              child: Transform.rotate(
                angle: _logoRotation.value * 3.14159,
                child: Opacity(
                  opacity: _logoOpacity.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFF9FAFB)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Shimmer effect
                        Positioned(
                          top: 24,
                          left: 24,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(_shimmerAnimation.value),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Logo icon
                        logoUrl.isEmpty
                            ? const Icon(Icons.shopping_bag, size: 56, color: AppColors.accentColor)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  logoUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.shopping_bag, size: 56, color: AppColors.accentColor),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        
        // App name
        SlideTransition(
          position: _textSlide,
          child: FadeTransition(
            opacity: _textOpacity,
            child: Text(
              appName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Tagline
        SlideTransition(
          position: _textSlide,
          child: FadeTransition(
            opacity: _textOpacity,
            child: Text(
              tagline,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainScreen() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Welcome text
          Column(
            children: [
              const Text(
                "Welcome Back!",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black12,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Choose how you'd like to continue with your journey",
                style: TextStyle(
                  fontSize: 19,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 48),
          
          // Auth buttons
          Column(
            children: [
              _buildAuthButton(
                text: "Log In",
                backgroundColor: Colors.white,
                textColor: AppColors.accentColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildAuthButton(
                text: "Sign Up",
                backgroundColor: Colors.white,
                textColor: AppColors.accentColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationApp()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildAuthButton(
                text: "Continue as Guest",
                backgroundColor: Colors.transparent,
                textColor: Colors.white,
                hasBorder: true,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CampusClosetScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    bool hasBorder = false,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: hasBorder
                ? Border.all(color: Colors.white.withOpacity(0.5), width: 2)
                : null,
            boxShadow: !hasBorder
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}