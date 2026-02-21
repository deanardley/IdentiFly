import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:identifly_flutter/admin_dashboard.dart';
import 'package:identifly_flutter/update_species.dart';
import 'package:identifly_flutter/user_list.dart';
import 'package:identifly_flutter/login.dart';
import 'package:identifly_flutter/pdf_viewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Identifly",
      home: PendingRequest(),
    );
  }
}


class PendingRequest extends StatefulWidget {
  const PendingRequest({super.key});

  @override
  State<PendingRequest> createState() => _PendingRequestState();
}

class _PendingRequestState extends State<PendingRequest> {

  String? currentUsername, currentUserEmail;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> pendingUsers = FirebaseFirestore.instance
        .collection('users')
        .where('status', isEqualTo: 'Pending')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[900],
        title: Text("Pending Requests", style: TextStyle(color: Colors.white),),
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
              onTap: (){
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => AdminDashboard()),
                );
              }
            ),
            ListTile(
              title: Text('Pending Requests'),
              leading: Icon(Icons.pending_actions),
            ),
            ListTile(
              title: Text('Users List'),
              leading: Icon(Icons.supervised_user_circle),
              onTap: (){
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => UserList()),
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
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (BuildContext context) => Login()),
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

      body: StreamBuilder<QuerySnapshot>(
        stream: pendingUsers,
        builder: (context, snapshot){
          if(!snapshot.hasData || snapshot.data!.docs.isEmpty){
            return Center(
              child: Text(
                "No pending requests.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index){
                var user = users[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Username: ${user['username']}"),
                        Text("Email: ${user['email']}"),
                        Text("Gender: ${user['gender']}"),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            final url = user['cert_url'];

                            if(url != null && url.isNotEmpty){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PdfViewer(url: url),
                                ),
                              );
                            }else{
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("No document available")),
                              );
                            }
                          },
                          child: Text(
                            "View Certificate",
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () async{
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text("Reject User"),
                                    content: Text("Are you sure you want to reject this user? \n\n${user['username']}"),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: (){
                                          Navigator.of(context).pop();
                                        },
                                        child: Text("No", style: TextStyle(color: Colors.green[800], fontSize: 15),),
                                      ),

                                      TextButton(
                                        onPressed: () async{
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text("User Rejected"))
                                          );
                                          await FirebaseFirestore.instance.collection('users').doc(user.id).update({'status': 'Rejected'});
                                        },
                                        child: Text("Yes", style: TextStyle(color: Colors.green[800], fontSize: 15),),
                                      )
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                "Reject",
                                style: TextStyle(fontSize: 15, color: Colors.white),
                              ),
                            ),

                            SizedBox(width: 10,),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () async{

                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text("Approve User"),
                                    content: Text("Are you sure you want to approve this user? \n\n${user['username']}"),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: (){
                                          Navigator.of(context).pop();
                                        },
                                        child: Text("No", style: TextStyle(color: Colors.green[800], fontSize: 15),),
                                      ),

                                      TextButton(
                                        onPressed: () async{
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text("User Approved"))
                                          );
                                          await FirebaseFirestore.instance.collection('users').doc(user.id).update({'status': 'Approved'});
                                          final Email email = Email(
                                            body: "Hello ${user['username']}, "
                                                "\nThis email is to notify you that your registration has already been approved by one of our admins."
                                                "Have fun using IdentiFly!"
                                                "\nRegards,"
                                                "\nIdentiFly Team",
                                            subject: "IdentiFly User Registration Approved",
                                            recipients: ['${user['email']}'],
                                            isHTML: false,
                                          );
                                          await FlutterEmailSender.send(email);
                                        },
                                        child: Text("Yes", style: TextStyle(color: Colors.green[800], fontSize: 15),),
                                      )
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                "Approve",
                                style: TextStyle(fontSize: 15, color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }
          );
        },
      ),
    );
  }
}
