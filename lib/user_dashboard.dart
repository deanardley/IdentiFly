import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:identifly_flutter/classify.dart';
import 'package:identifly_flutter/login.dart';
import 'package:identifly_flutter/species_information.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class ChartData{
  ChartData(this.x, this.y, this.color);
  final String x;
  final int y;
  Color color;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "IdentiFly",
      home: UserDashboard(),
    );
  }
}

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {

  int countMegacephala = 0, countRufifacies = 0, countLigurriens = 0;
  String? currentUser, currentUsername, currentUserEmail;
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  @override
  initState(){
    super.initState();
    countClassification();
    loadCurrentUser();
  }
  
  Future<void> countClassification() async{
    final user = auth.currentUser;
    
    firestore.collection('classification')
        .where('species', isEqualTo: 'Chrysomya megacephala')
        .where('userId', isEqualTo: user?.uid)
        .snapshots().listen((snapshot){
          setState(() {
            countMegacephala = snapshot.docs.length;
          });
        });

    firestore.collection('classification')
        .where('species', isEqualTo: 'Chrysomya rufifacies')
        .where('userId', isEqualTo: user?.uid)
        .snapshots().listen((snapshot){
          setState(() {
            countRufifacies = snapshot.docs.length;
          });
        });

    firestore.collection('classification')
        .where('species', isEqualTo: 'Hemipyrellia ligurriens')
        .where('userId', isEqualTo: user?.uid)
        .snapshots().listen((snapshot){
          setState(() {
            countLigurriens = snapshot.docs.length;
          });
        });
  }

  Future<void> loadCurrentUser() async{
    final user = auth!.currentUser;

    if(user == null){
      return;
    }

    final doc = await firestore!.collection('users').doc(user?.uid).get();

    if(doc.exists){
      setState(() {
        currentUser = doc.data()!["username"];
        currentUserEmail = doc.data()!["email"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("User Dashboard", style: TextStyle(color: Colors.white),),
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
                accountName: Text(currentUser ?? "Loading..", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                accountEmail: Text(currentUserEmail ?? "Loading.."),
              ),
            ),

            ListTile(
              title: Text("Dashboard"),
              leading: Icon(Icons.bar_chart),
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

      body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  Text(
                    "Hello, $currentUser",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 10,),

                  SizedBox(
                    height: 300,
                    width: 350,
                    child: SfCartesianChart(
                      primaryXAxis: CategoryAxis(),
                      series: <CartesianSeries>[
                        ColumnSeries<ChartData, String>(
                          dataSource: [
                            ChartData("C. megacephala", countMegacephala, Colors.orange),
                            ChartData("H. ligurriens", countLigurriens, Colors.purple),
                            ChartData("C. rufifacies", countRufifacies, Colors.blue),
                          ],
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          pointColorMapper: (ChartData data, _) => data.color,
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            Positioned(
              right: 25,
              bottom: 40,
              child: FloatingActionButton(
                backgroundColor: Colors.green[100],
                onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Classify(),
                    ),
                  );
                },
                child: Icon(Icons.camera_alt, color: Colors.black),
              ),
            ),
          ]
      ),
    );
  }
}
