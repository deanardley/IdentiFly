import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(UpdateSpecies(speciesName: ''));
}

class UpdateSpecies extends StatefulWidget {
  final String speciesName;
  const UpdateSpecies({super.key, required this.speciesName});

  @override
  State<UpdateSpecies> createState() => _UpdateSpeciesState();
}

class _UpdateSpeciesState extends State<UpdateSpecies> {
  TextEditingController regularNameController = TextEditingController();
  TextEditingController speciesNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  String? speciesDocID;

  @override
  void initState(){
    super.initState();
    retrieveSpecies();
  }

  Future<void> updateSpecies() async{
    try{
      await FirebaseFirestore.instance.collection('species').doc(speciesDocID).update({
        'speciesName': speciesNameController.text.trim(),
        'regularName': regularNameController.text.trim(),
        'description': descriptionController.text.trim()
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Species update successfully."))
      );

      Navigator.pop(context);
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating species: $e"))
      );
    }
  }

  Future<void> retrieveSpecies()async {
    final firestore = FirebaseFirestore.instance;

    try{
      final query = await firestore.collection('species').where('speciesName', isEqualTo: widget.speciesName).get();

      if(query.docs.isNotEmpty){
        final doc = query.docs.first;
        setState(() {
          speciesDocID = doc.id;
          speciesNameController.text = doc['speciesName'];
          regularNameController.text = doc['regularName'];
          descriptionController.text = doc['description'];
        });
      }

    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        title: Text("Update Species", style: TextStyle(color: Colors.white),),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 25),
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
                  padding: EdgeInsets.all(25.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: regularNameController,
                        decoration: InputDecoration(
                          hintText: "Regular Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),

                      SizedBox(height: 10,),

                      TextField(
                        controller: speciesNameController,
                        decoration: InputDecoration(
                          hintText: "Species Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),

                      SizedBox(height: 10,),

                      TextField(
                        maxLines: null,
                        controller: descriptionController,
                        decoration: InputDecoration(
                          hintText: "Description",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),

                      SizedBox(height: 10,),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[800]
                        ),
                        onPressed: updateSpecies,
                        child: Text(
                          "Update",
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ),

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
