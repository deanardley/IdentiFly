import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:identifly_flutter/login.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  await Supabase.initialize(
    url: 'https://jwqylkdaczmorisysvnl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3cXlsa2RhY3ptb3Jpc3lzdm5sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI1NzEzMTcsImV4cCI6MjA3ODE0NzMxN30.V6yxVDCuwKQ2wNs0mBx0qtqAbAj1mHcOXffZOz7-Uk8',
  );

  runApp(MaterialApp(
      home: const Register())
  );
}

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {

  //Controllers
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? gender;
  String fileName = "No file currently";
  File? selectedFile;

  Future<void> _selectFile() async{
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    
    if(result != null && result.files.single.name != null){
      setState(() {
        selectedFile = File(result.files.single.path!);
        fileName = result.files.single.name;
      });
    }
  }

  Future<void> _registerUser() async{
    String username = usernameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if(username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields.")),
      );
      return;
    }

    if(password != confirmPassword){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    if(selectedFile == null){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a PDF file.")),
      );
      return;
    }

    try{
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
      );

      final supabase = Supabase.instance.client;

      final fileBytes = await selectedFile!.readAsBytes();
      final filePath = 'certificates/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await supabase.storage.from('certificates').uploadBinary(
        filePath,
        fileBytes,
        fileOptions: const FileOptions(contentType: 'application/pdf'),
      );
      final fileUrl = supabase.storage.from('certificates').getPublicUrl(filePath);
      print("Uploaded file URL: $fileUrl");

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'gender': gender ?? '',
        'role': 'User',
        'status': 'Pending',
        'cert_url': fileUrl,
        'timeCreated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration Successful.")),
      );

      Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) => Login()),
      );

    }on FirebaseAuthException catch (e){
      String errorMessage = "";
      if(e.code == 'email-already-in-use'){
        errorMessage = "Email already in use";
      }else{
        errorMessage = e.message ?? "Registration failed";
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
      );
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
                "Start you journey today!",
                style: TextStyle(
                    fontSize: 37,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 10),

              Card(
                  color: Colors.grey[200],
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            hintText: "Username",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "Email",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "Password",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "Confirm Password",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Text(
                              "Gender: ",
                              style: TextStyle(fontSize: 18),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Row(
                                    children: [
                                      Radio(
                                        value: "Male",
                                        groupValue: gender,
                                        onChanged: (value){
                                          setState(() => gender = value);
                                        },
                                      ),
                                      Text("Male", style: TextStyle(fontSize: 15),)
                                    ],
                                  ),

                                  SizedBox(width: 2,),

                                  Row(
                                    children: [
                                      Radio(
                                        value: "Female",
                                        groupValue: gender,
                                        onChanged: (value){
                                          setState(() => gender = value);
                                        },
                                      ),
                                      Text("Female", style: TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis,)
                                    ]
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Certification: ",
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fileName,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    SizedBox(height: 5),

                                    Center(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[800]
                                        ),
                                        onPressed: (){
                                          _selectFile();
                                        },
                                        child: Text("Upload Certificate", style: TextStyle(fontSize: 15, color: Colors.white),),
                                      ),
                                    ),

                                  ],
                                )
                            )
                          ],
                        ),

                        SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                              onPressed: (){
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (BuildContext context) => Login()),
                                );
                              },
                              child: Text(
                                "Back",
                                style: TextStyle(fontSize: 15, color: Colors.black),
                              ),
                            ),

                            SizedBox(width: 10,),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[800]
                              ),
                                onPressed: (){
                                  _registerUser();
                                },
                                child: Text(
                                  "Register",
                                  style: TextStyle(fontSize: 15, color: Colors.white),
                                )
                            )
                          ],
                        )
                      ],
                    ),
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
