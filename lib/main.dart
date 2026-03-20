// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialize Supabase ──────────────────────────────────────────────────
  // Replace the placeholders below with your project URL and anon key from
  // https://supabase.com/dashboard → Project Settings → API
  await Supabase.initialize(
    url: 'https://udjcqoepfcbjpcfnqakc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVkamNxb2VwZmNianBjZm5xYWtjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4ODM4MjMsImV4cCI6MjA4OTQ1OTgyM30.77mXNpaFxiwnlGAggRTAK2H-3TMeQuBhl1cNCBaE9YA',
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: SDSUMerchApp(),
    ),
  );
}

class SDSUMerchApp extends StatelessWidget {
  const SDSUMerchApp({super.key});

  @override
  Widget build(BuildContext context) {
    // If there is already an active session (user reopens the app while
    // still logged-in), go straight to HomeScreen.
    final initialRoute = Supabase.instance.client.auth.currentSession != null
        ? const HomeScreen()
        : const WelcomeScreen();

    return MaterialApp(
      title: 'SDSU Merch Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: initialRoute,
    );
  }
}