import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:identifly_flutter/pdf_viewer.dart';

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
      title: "IdentiFly",
      home: Scaffold(
        appBar: AppBar(title: Text("Update User"),),
      ),
    );
  }
}

class UpdateUser extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UpdateUser({super.key, required this.userId, required this.userData});

  @override
  State<UpdateUser> createState() => _UpdateUserState();
}

class _UpdateUserState extends State<UpdateUser> {
  //Controllers
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();


  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? gender;
  File? selectedFile;
  String fileName = "No file currently";

  @override
  void initState(){
    super.initState();
    usernameController.text = widget.userData['username'];
    emailController.text = widget.userData['email'];
    gender = widget.userData['gender'];
    fileName = widget.userData['cert_url'] != null
        ? widget.userData['cert_url'].split('/').last
        : 'No file currently';
  }

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

  Future<void> updateUser() async{
    try{
      String? fileUrl;
      /*
      if(selectedFile != null){
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${selectedFile!.path.split('/').last}';
        final reference = FirebaseStorage.instance.ref().child('certificates/$fileName');
        await reference.putFile(selectedFile!);
        fileUrl = await reference.getDownloadURL();
      }
      */
      if(selectedFile != null){
        final supabase = Supabase.instance.client;

        final fileBytes = await selectedFile!.readAsBytes();
        final filePath = 'certificates/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        await supabase.storage.from('certificates').uploadBinary(
          filePath,
          fileBytes,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );

        fileUrl = supabase.storage.from('certificates').getPublicUrl(filePath);
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'gender': gender,
        if(fileUrl != null) 'cert_url': fileUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User updated successfully.")),
      );



    }catch (e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating user: $e")),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        title: Text("Update User", style: TextStyle(color: Colors.white),),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

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
                                      Text("Male", style: TextStyle(fontSize: 15)),
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
                                      Text("Female", style: TextStyle(fontSize: 15)),
                                    ],
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
                              style: TextStyle(fontSize: 18,),
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

                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[100]
                                      ),
                                        onPressed: (){
                                          final url = widget.userData['cert_url'];

                                          if(url != null && url.isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => PdfViewer(url: url),
                                              ),
                                            );
                                          }
                                        },
                                        child: Text(
                                          "Current Certificate",
                                          style: TextStyle(fontSize: 15, color: Colors.black),
                                        ),
                                    ),

                                    SizedBox(height: 5),

                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[800],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        )
                                      ),
                                        onPressed: (){
                                          _selectFile();
                                        },
                                        child: Text(
                                          "Upload Certificate",
                                          style: TextStyle(fontSize: 15, color: Colors.white),
                                        )
                                    )
                                  ],
                                ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                              ),
                              onPressed: (){
                                Navigator.pop(context);
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
                                  updateUser();
                                },
                                child: Text(
                                  "Update",
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
