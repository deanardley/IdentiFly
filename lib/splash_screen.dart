import 'dart:async';
import 'package:flutter/material.dart';
import 'package:identifly_flutter/login.dart';
import 'package:page_transition/page_transition.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      Timer(const Duration(seconds: 3), () {
        Navigator.push(
            context,
            PageTransition(
              child: const Login(),
              type: PageTransitionType.rightToLeft,
            )
        );
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: FlutterLogo(size: 150,),
      ),
    );
  }
}
