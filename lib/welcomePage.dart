import 'package:flutter/material.dart';
import 'package:profile_managemenr/accounts/authentication/login.dart';
import 'package:profile_managemenr/accounts/registration/registration.dart';
import 'package:profile_managemenr/main.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome',
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.fromARGB(255, 1, 183, 255), Color.fromARGB(255, 20, 152, 188)],
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
                  color: const Color.fromARGB(255, 6, 201, 255),
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
                        colors: [Color.fromARGB(255, 253, 253, 253), Color.fromARGB(255, 255, 255, 255)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 54, 54, 54).withOpacity(0.3),
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
                            ? const Icon(Icons.phone_android, size: 56, color: Colors.white)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  logoUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.phone_android, size: 56, color: Colors.white),
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
                color: Color.fromARGB(255, 255, 255, 255),
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
              style: TextStyle(
                fontSize: 17.6,
                color: const Color(0xFF718096),
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
              Text(
                welcomeMessage,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Color.fromARGB(255, 255, 255, 255),
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
                  fontSize: 19.2,
                  color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.9),
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
                gradient: const LinearGradient(colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)]),
                textColor: const Color.fromARGB(255, 10, 179, 205),
                onPressed: () {
                  Navigator.push(context,
                  MaterialPageRoute(builder: (context) => LoginPage() ));
                }
              ),
              const SizedBox(height: 16),
              _buildAuthButton(
                text: "Sign Up",
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 255, 255, 255),
                    const Color.fromARGB(255, 255, 255, 255),
                  ],
                ),
                textColor: const Color.fromARGB(255, 10, 172, 216),
                hasBorder: true,
                onPressed: () {
                  Navigator.push(context,
                  MaterialPageRoute(builder: (context) => RegistrationApp() ));
                }
              ),
              const SizedBox(height: 16),
              _buildAuthButton(
                text: "Continue as Guest",
                gradient: const LinearGradient(colors: [Color.fromARGB(0, 0, 0, 0), Colors.transparent]),
                textColor: Colors.white,
                hasBorder: true,
                onPressed: () {
                  Navigator.push(context,
                  MaterialPageRoute(builder: (context) => CampusClosetScreen() ));
                }
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton({
    required String text,
    required Gradient gradient,
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
            gradient: gradient,
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
              fontSize: 17.6,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}