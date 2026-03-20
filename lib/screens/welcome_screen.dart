// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800&q=80',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0D1B4B)),
          ),

          // Dark gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 0.65, 1.0],
                colors: [
                  Color(0x33000000),
                  Color(0x22000000),
                  Color(0xCC000000),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SDSU Logo badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'SDSU',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Headline
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Build Your\n',
                          style: GoogleFonts.outfit(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                        TextSpan(
                          text: 'SDSU Merch\n',
                          style: GoogleFonts.outfit(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                        TextSpan(
                          text: 'Order',
                          style: GoogleFonts.outfit(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Discover the latest trends in fashion,\ncustomized for Jackrabbits.',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.75),
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        'Log In',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Create Account button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        'Create Account',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Terms note
                  Center(
                    child: Text(
                      'By continuing, you agree to our Terms & Privacy Policy',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.45),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}