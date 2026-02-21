import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:identifly_flutter/admin_dashboard.dart';
import 'package:identifly_flutter/classify.dart';
import 'package:identifly_flutter/login.dart';
import 'package:identifly_flutter/main_admin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:identifly_flutter/splash_screen.dart';
import 'package:identifly_flutter/user_dashboard.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Supabase.initialize(
    url: 'https://jwqylkdaczmorisysvnl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3cXlsa2RhY3ptb3Jpc3lzdm5sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI1NzEzMTcsImV4cCI6MjA3ODE0NzMxN30.V6yxVDCuwKQ2wNs0mBx0qtqAbAj1mHcOXffZOz7-Uk8',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "IdentiFly",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),

      initialRoute: '/splash_screen',
      routes: {
        '/login': (context) => const Login(),
        '/classify': (context) => const Classify(),
        '/main_admin': (context) => const MainAdmin(),
        '/splash_screen': (context) => const SplashScreen(),
        '/user_dashboard': (context) => const UserDashboard(),
        '/admin_dashboard': (context) => const AdminDashboard()
      },
    );
  }
}
