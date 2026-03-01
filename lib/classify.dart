import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:identifly_flutter/species_information.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
      home: Classify(),
  ));
}

class Classify extends StatefulWidget {
  const Classify({super.key});

  @override
  State<Classify> createState() => _ClassifyState();
}

class _ClassifyState extends State<Classify> {
  final imagePicker = ImagePicker();
  Interpreter? interpreter;
  String? result, predictedSpecies;
  File? imageFile;
  XFile? pickedImage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset("assets/fly_species_classifier_cnn.tflite");
      print('Model loaded from assets');
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  Future<void> openCamera() async{
    pickedImage = await imagePicker.pickImage(source: ImageSource.camera);
    if(pickedImage != null){
      setState(() {
        imageFile = File(pickedImage!.path);
        result = null;
      });
    }
  }

  Future<void> selectImage() async{
    pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);
    if(pickedImage != null){
      setState(() {
        imageFile = File(pickedImage!.path);
        result = null;
      });
    }
  }

  Future<void> _classifyImage() async{
    if(imageFile == null || interpreter == null){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select an image.")),
      );
      return;
    }

    final bytes = await imageFile!.readAsBytes();
    img.Image? imageInput = img.decodeImage(bytes);

    if(imageInput == null){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load image")),
      );
      return;
    }

    imageInput = img.copyResize(imageInput, width: 224, height: 224);
    var input = List.generate(1, (i) => List.generate(224, (y) => List.generate(224, (x){
      final pixel = imageInput!.getPixel(x, y);
      return[
        img.getRed(pixel) / 255.0,
        img.getGreen(pixel) / 255.0,
        img.getBlue(pixel) / 255.0
      ];
    })));
    var output = List.filled(3, 0.0).reshape([1, 3]);

    interpreter!.run(input, output);

    int maxIndex = 0;
    const double CONFIDENCE_THRESHOLD = 0.99;
    double maxConfidence = output[0][0];

    for(int i = 1; i < output[0].length; i++){
      if(output[0][i] > maxConfidence){
        maxConfidence = output[0][i];
        maxIndex = i;
      }
    }

    //Error Code
    if(maxConfidence < CONFIDENCE_THRESHOLD){
      _showNotFlyDialog();
      return;
    }

    final speciesName = ["Chrysomya megacephala", "Chrysomya rufifacies", "Hemipyrellia ligurriens"];
    final predictedSpecies = speciesName[maxIndex];

    setState(() {
      result = predictedSpecies;
    });

    _showDialog(predictedSpecies!, maxConfidence);

    if(maxConfidence >= CONFIDENCE_THRESHOLD){
      final user = _auth.currentUser;
      await _firestore.collection('classification').add({
        'userId': user?.uid,
        'species': predictedSpecies,
        'accuracy': maxConfidence,
        'timeCreated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _showNotFlyDialog() async{
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(20),
        ),
        backgroundColor: Colors.grey[100],
        contentPadding: EdgeInsets.all(20),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                Icon(Icons.error_outline, size: 60, color: Colors.red,),
                
                SizedBox(height: 18,),
                
                Text("Invalid Image", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),

                SizedBox(height: 10,),

                Text(
                  "The image can't be classified. Please try again.",
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 10,),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(30)
                          ),
                          backgroundColor: Colors.green[800]
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "OK",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        )
      ),
    );
  }

  Future<void> _showDialog(String species, double maxConfidence) async{
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(20),
        ),
        backgroundColor: Colors.grey[100],
        contentPadding: EdgeInsets.all(20),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if(imageFile != null) Image.file(imageFile!, height: 224, width: 224,),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  species,
                  style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: Colors.green[800]),
                  textAlign: TextAlign.center,
                ),

                Text(
                  "Accuracy: ${(maxConfidence * 100).toStringAsFixed(2)}%",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 10,),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(30),
                        ),
                      ),
                      onPressed: () => {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (BuildContext context) => SpeciesInformation(speciesName: result ?? "No result.",)),
                        ),
                      },
                      child: Text(
                        "View Information",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(30)
                        ),
                        backgroundColor: Colors.white
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Close",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            )


          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  @override
  void dispose() async{
    super.dispose();
    interpreter?.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Classify", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green[800],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Enter an image: ",
                style: TextStyle(fontSize: 20),
              ),

              SizedBox(height: 20),

              Container(
                height: 224,
                width: 224,
                child: imageFile != null
                    ? Image.file(imageFile!, fit: BoxFit.cover,)
                    : Center(child: Text("No image selected")),
              ),

              SizedBox(height: 20),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.green[100]
                      ),
                      child: IconButton(
                        iconSize: 30,
                        onPressed: openCamera,
                        icon: Icon(Icons.camera_alt, color: Colors.black),
                      ),
                    ),

                    SizedBox(width: 20,),

                    Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.green[100]
                      ),
                      child: IconButton(
                        iconSize: 30,
                        onPressed: selectImage,
                        icon: Icon(Icons.image, color: Colors.black),
                      ),
                    )
                  ],
                ),
              ),
              
              SizedBox(height: 10,),
              
              ElevatedButton(
                onPressed: _classifyImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)
                  )
                ),
                
                child: Text(
                  "Predict",
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
                
              ),
            ],
          ),
        ),
      ),
    );
  }
}
