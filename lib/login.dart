import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:identifly_flutter/admin_dashboard.dart';
import 'package:identifly_flutter/user_dashboard.dart';
import 'package:path/path.dart' as p;
import 'package:identifly_flutter/main_admin.dart';
import 'package:identifly_flutter/classify.dart';
import 'package:identifly_flutter/pending_request.dart';
import 'package:identifly_flutter/register.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Supabase.initialize(
    url: 'https://jwqylkdaczmorisysvnl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3cXlsa2RhY3ptb3Jpc3lzdm5sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI1NzEzMTcsImV4cCI6MjA3ODE0NzMxN30.V6yxVDCuwKQ2wNs0mBx0qtqAbAj1mHcOXffZOz7-Uk8',
  );

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "IdentiFly",
      home: Login(),
      routes: {
        '/classify': (context) => const Classify(),
        '/main_admin': (context) => const MainAdmin(),
        '/pending_request': (context) => const PendingRequest(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/user_dashboard': (context) => const UserDashboard(),
      },
    );
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {

  //Controllers
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  String? selectedRole;

  Future<void> _Login() async{
    String emailInput = emailController.text.trim();
    String passwordInput = passwordController.text.trim();

    if(emailInput.isEmpty || passwordInput.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill every field."))); return;
    }

    try{
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailInput,
          password: passwordInput
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();

      if(!userDoc.exists){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User not found.")));
        return;
      }

      String storedRole = userDoc['role'];
      String storedStatus = userDoc['status'];

      if(storedRole != selectedRole){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Role mismatch. Please select the correct role.")));
        return;
      }

      if(storedRole == 'Admin' && storedStatus == 'Approved'){
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      }else if(storedRole == 'User' && storedStatus == 'Approved'){
        Navigator.pushReplacementNamed(context, '/user_dashboard');
      }

    }on FirebaseAuthException catch (e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Login failed.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welcome to IdentiFly!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 37,
                  color: Colors.green[800],
                ),
              ),
              SizedBox(height: 10),
              Card(
                color: Colors.grey[200],
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(
                                "Admin",
                                style: TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              value: "Admin",
                              groupValue: selectedRole,
                              onChanged: (value){
                                setState(() => selectedRole = value);
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(
                                "User",
                                style: TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              value: "User",
                              groupValue: selectedRole,
                              onChanged: (value) {
                                setState(() => selectedRole = value);
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),

                      SizedBox(height: 10),

                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10)
                        ),
                      ),
                      SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[800]
                            ),
                            onPressed: (){
                              _Login();
                            },
                            child: Text(
                              "Log In",
                              style: TextStyle(fontSize: 15, color: Colors.white),
                            ),
                          ),
                          SizedBox(height: 10,),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200]
                            ),
                            onPressed: (){
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) => Register(),
                              ));
                            },
                            child: Text("Register", style: TextStyle(color: Colors.black),),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

              )
            ],
          ),
        ),
      ),
    );
  }
}
