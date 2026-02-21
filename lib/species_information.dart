import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:identifly_flutter/login.dart';
import 'package:identifly_flutter/user_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: SpeciesInformation(speciesName: '',)));
}

class SpeciesInformation extends StatefulWidget {
  final String speciesName;
  const SpeciesInformation({super.key, required this.speciesName});

  @override
  State<SpeciesInformation> createState() => _SpeciesInformationState();
}

class _SpeciesInformationState extends State<SpeciesInformation> {
  String? currentUsername, currentUserEmail, speciesDesc, retrievedSpecies, regularName, imagePath;
  ImageProvider? speciesImage;

  @override
  void initState() {
    super.initState();
    retrieveCurrentUser();
    retrieveInformation();
  }

  Future<void> retrieveInformation() async {
    final firestore = FirebaseFirestore.instance;

    try {
      final query = await firestore
          .collection('species')
          .where('speciesName', isEqualTo: widget.speciesName)
          .get();

      if(widget.speciesName == "Chrysomya megacephala"){
        imagePath = 'assets/images/1.jpg';
      }else if(widget.speciesName == "Chrysomya rufifacies"){
        imagePath = 'assets/images/13.jpg';
      }else{
        imagePath = 'assets/images/25.jpeg';
      }

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        setState(() {
          retrievedSpecies = doc['speciesName'];
          regularName = doc['regularName'];
          speciesDesc = doc['description'];
        });
      } else {
        setState(() {
          retrievedSpecies = "No species found.";
          regularName = "No name found";
          speciesDesc = "No description found.";

        });
      }
    } catch (e) {
      debugPrint("Error fetching species: $e");
      setState(() {
        retrievedSpecies = "Error";
        speciesDesc = "Failed to load species info.";
      });
    }
  }

  Future<void> retrieveCurrentUser() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          currentUsername = doc['username'];
          currentUserEmail = doc['email'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Species Information", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green[800],
        iconTheme: IconThemeData(color: Colors.white),
      ),

      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green[800],
              ),
              child: UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Colors.green[800]),
                accountName: Text(currentUsername ?? "Loading..", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                accountEmail: Text(currentUserEmail ?? "Loading.."),
              ),
            ),

            ListTile(
              title: Text("Dashboard"),
              leading: Icon(Icons.bar_chart),
              onTap: (){
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => UserDashboard(),)
                );
              },
            ),

            ExpansionTile(
              title: Text("Species Information"),

              children: [
                ListTile(
                  title: Text("C. megacephala"),
                  onTap: (){
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => SpeciesInformation(speciesName: 'Chrysomya megacephala',),)
                    );
                  },
                ),
                ListTile(
                  title: Text("C. rufifacies"),
                  onTap: (){
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => SpeciesInformation(speciesName: 'Chrysomya rufifacies',),)
                    );
                  },
                ),

                ListTile(
                  title: Text("H. ligurriens"),
                  onTap: (){
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => SpeciesInformation(speciesName: 'Hemipyrellia ligurriens',),)
                    );
                  },
                ),
              ],
            ),

            ListTile(
              title: Text("Log Out"),
              leading: Icon(Icons.logout),
              onTap: (){
                showDialog(
                  context: context,
                  builder: (BuildContext context){
                    return AlertDialog(
                      title: Text("Log Out"),
                      content: Text("Are you sure you want to log out?"),
                      actions: [
                        TextButton(
                          onPressed: (){
                            Navigator.of(context).pop();
                          },
                          child: Text("No", style: TextStyle(color: Colors.green[800], fontSize: 15),),
                        ),

                        TextButton(
                          onPressed: (){
                            Navigator.pop(context);
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (BuildContext context) => Login(),)
                            );
                          },
                          child: Text("Yes", style: TextStyle(color: Colors.green[800], fontSize: 15),),
                        ),
                      ],
                    );
                  },
                );
              },
            )
          ],
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(imagePath ?? "Loading.."),
                    fit: BoxFit.cover
                )
            ),
          ),

          SizedBox(height: 10,),

          Padding(
            padding: EdgeInsets.all(15),
              child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(regularName ?? "Loading..", style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold,),),
                      SizedBox(height: 5,),
                      Text(retrievedSpecies ?? "Loading..", style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),),
                      SizedBox(height: 20,),
                      Text("DESCRIPTION", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]),),
                      SizedBox(height: 5,),
                      Text(
                        speciesDesc ?? "Loading..",
                        style: TextStyle(fontSize: 15),
                      )

                    ]
                ),
              )



          )
        ],
      ),
    );
  }
}