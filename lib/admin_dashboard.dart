import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:identifly_flutter/login.dart';
import 'package:identifly_flutter/pending_request.dart';
import 'package:identifly_flutter/user_dashboard.dart';
import 'package:identifly_flutter/user_list.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:identifly_flutter/update_species.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "IdentiFly",
      home: AdminDashboard(),
    );
  }
}

class ChartData{
  ChartData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {

  int approvedCount = 0, pendingCount = 0, rejectedCount = 0, maleCount = 0, femaleCount = 0;
  String? currentUsername, currentUserEmail;

  @override
  void initState(){
    super.initState();
    fetchUsersCount();
    countGender();
    retrieveCurrentUser();
  }

  Future<void> retrieveCurrentUser() async{
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if(user != null){
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if(doc.exists){
        setState(() {
          currentUsername = doc['username'];
          currentUserEmail = doc['email'];
        });
      }else{
        return;
      }
    }
  }

  Future<void> fetchUsersCount() async{
    final firestore = FirebaseFirestore.instance;
    try{
      final approvedSnapshot = await firestore.collection('users')
          .where('status', isEqualTo: 'Approved')
          .where('role', isEqualTo: 'User')
          .get();

      final pendingSnapshot = await firestore.collection('users')
          .where('status', isEqualTo: 'Pending')
          .where('role', isEqualTo: 'User')
          .get();

      final rejectedSnapshot = await firestore.collection('users')
          .where('status', isEqualTo: 'Rejected')
          .where('role', isEqualTo: 'User')
          .get();

      setState(() {
        approvedCount = approvedSnapshot.size;
        pendingCount = pendingSnapshot.size;
        rejectedCount = rejectedSnapshot.size;
      });
    }catch(e){
      print("Error fetching user counts: $e");
    }
  }

  Future<void> countGender() async{
    final firestore = FirebaseFirestore.instance;
    try{
      final maleSnapshot = await firestore.collection('users')
          .where('gender', isEqualTo: 'Male')
          .where('status', isEqualTo: 'Approved')
          .where('role', isEqualTo: 'User').get();

      final femaleSnapshot = await firestore.collection('users')
          .where('gender', isEqualTo: 'Female')
          .where('status', isEqualTo: 'Approved')
          .where('role', isEqualTo: 'User').get();

      setState(() {
        maleCount = maleSnapshot.size;
        femaleCount = femaleSnapshot.size;
      });
    }catch(e){
      print("Error fetching gender counts: ${e}");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: TextStyle(color: Colors.white),),
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
              title: Text('Dashboard'),
              leading: Icon(Icons.bar_chart),
            ),
            ListTile(
              title: Text('Pending Requests'),
              leading: Icon(Icons.pending_actions),
              onTap: (){
                Navigator.pop(context);
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: const PendingRequest(),
                    duration: Duration(milliseconds: 1000),
                    curve: Curves.easeOutBack,
                  ),
                );
              },
            ),
            ListTile(
              title: Text('Users List'),
              leading: Icon(Icons.supervised_user_circle),
              onTap: (){
                Navigator.pop(context);
                Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.rightToLeft,
                      child: const UserList(),
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.easeOutBack,
                    ),
                );
              },
            ),

            ExpansionTile(
              title: Text("Update Information"),

              children: [
                ListTile(
                  title: Text("C. megacephala"),
                  onTap: (){
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => UpdateSpecies(speciesName: 'Chrysomya megacephala',),)
                    );
                  },
                ),
                ListTile(
                  title: Text("C. rufifacies"),
                  onTap: (){
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => UpdateSpecies(speciesName: 'Chrysomya rufifacies',),)
                    );
                  },
                ),

                ListTile(
                  title: Text("H. ligurriens"),
                  onTap: (){
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => UpdateSpecies(speciesName: 'Hemipyrellia ligurriens',),)
                    );
                  },
                ),
              ],
            ),

            ListTile(
              title: Text('Log Out'),
              leading: Icon(Icons.logout),
              onTap: (){
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Log Out"),
                      content: Text("Are you sure you want to log out?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text("No", style: TextStyle(color: Colors.green[800], fontSize: 15),),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.rightToLeft,
                                child: const Login(),
                                duration: Duration(milliseconds: 1000),
                                curve: Curves.easeOutBack
                              ),
                            );
                          },
                          child: Text("Yes", style: TextStyle(color: Colors.green[800], fontSize: 15),),
                        ),
                      ],
                    );
                  }
                );
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20,),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        "Hello, $currentUsername",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ).animate().fade(delay: 500.ms).slide(),
                    ),

                    SizedBox(height: 10,),

                    Card(
                      color: Colors.green[100],
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Approved Users:",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              approvedCount.toString(),
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade(delay: 500.ms).slide(),
                    SizedBox(width: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.red[100],
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(18),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Rejected Users:",
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    rejectedCount.toString(),
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fade(delay: 500.ms).slide(),
                        ),

                        SizedBox(width: 5),

                        Expanded(
                          child: Card(
                            color: Colors.orange[100],
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(18),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Pending Users:",
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    pendingCount.toString(),
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fade(delay: 500.ms).slide(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20,),

              Center(
                child: Column(
                  children: [
                    Text(
                      "Gender Distribution",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ).animate().fade(delay: 500.ms).slide(),

                    SizedBox(height: 10,),

                    SizedBox(
                      height: 300,
                      width: 400,
                      child: SfCircularChart(
                        legend: Legend(
                          isVisible: true,
                          position: LegendPosition.bottom,
                        ),
                        series: <CircularSeries>[
                          PieSeries<ChartData, String>(
                            dataSource: [
                              ChartData("Male", maleCount.toDouble(), Colors.lightBlue),
                              ChartData("Female", femaleCount.toDouble(), Colors.pinkAccent)
                            ],
                            xValueMapper: (ChartData data, _) => data.x,
                            yValueMapper: (ChartData data, _) => data.y,
                            pointColorMapper: (ChartData data, _) => data.color,
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              labelPosition: ChartDataLabelPosition.outside,
                            ),
                            radius: "100%",
                          )
                        ],
                      ).animate().fade(delay: 500.ms).slide(),
                    )
                  ],
                ),
              ),

            ],
          ),
      ),
    );
  }
}
