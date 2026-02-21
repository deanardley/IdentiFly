import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:identifly_flutter/pdf_viewer.dart';
import 'package:identifly_flutter/update_user.dart';
import 'package:identifly_flutter/login.dart';
import 'package:identifly_flutter/pending_request.dart';
import 'package:identifly_flutter/admin_dashboard.dart';
import 'package:identifly_flutter/update_species.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "IdentiFly",
      home: UserList(),
    );
  }
}

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  State<UserList> createState() => _UserListState();
}



class _UserListState extends State<UserList> {
  String searchName = "";
  final TextEditingController searchController = TextEditingController();
  String? currentUsername, currentUserEmail;
  
  @override
  initState(){
    super.initState();
    retrieveCurrentUser();
  }
  
  Future<void> retrieveCurrentUser()async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    
    if(user != null){
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if(doc.exists){
        setState(() {
          currentUsername = doc['username'];
          currentUserEmail = doc['email'];
        });
      }
    }else{
      return;
    }
  }
  
  Future<void> showInformation(Map<String, dynamic> userData) async{
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),

        contentPadding: EdgeInsets.all(20),

        backgroundColor: Colors.grey[100],

        title: Text(
          "User Information",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Username:", style: TextStyle(fontSize: 17),),
            Text("${userData['username'] ?? 'N/A'}", style: TextStyle(fontSize: 17),),

            SizedBox(height: 10,),

            Text("Email:", style: TextStyle(fontSize: 17),),
            Text("${userData['email'] ?? 'N/A'}", style: TextStyle(fontSize: 17),),

            SizedBox(height: 10,),

            Text("Gender:", style: TextStyle(fontSize: 17),),
            Text("${userData['gender'] ?? 'N/A'}", style: TextStyle(fontSize: 17),),

            SizedBox(height: 10,),

            Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      final url = userData['cert_url'];

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
                    child: Text("View Certificate", style: TextStyle(fontSize: 15, color: Colors.white),),
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text("Close", style: TextStyle(fontSize: 15, color: Colors.black),),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> approvedUsers = FirebaseFirestore.instance
        .collection('users').where('status', isEqualTo: 'Approved').where('role', isEqualTo: 'User').snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Users', style: TextStyle(color: Colors.white),),
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
                onTap: (){
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => AdminDashboard()),
                  );
                }
            ),
            ListTile(
              title: Text('Pending Requests'),
              leading: Icon(Icons.pending_actions),
              onTap: (){
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => PendingRequest())
                );
              }
            ),
            ListTile(
              title: Text('Users List'),
              leading: Icon(Icons.supervised_user_circle),
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

      body: StreamBuilder(
        stream: approvedUsers,
        builder: (context, snapshot){
          if(!snapshot.hasData || snapshot.data!.docs.isEmpty){
            return Center(
              child: Text(
                "No users.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final allApprovedUsers = snapshot.data!.docs;

          final filteredUsers = allApprovedUsers.where((user){
            final username = user['username'].toString().toLowerCase();
            return username.contains(searchName.toLowerCase());
          }).toList();

          return Column(
            children: [
              Card(
              color: Colors.green[100],
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
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Search name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      SizedBox(height: 10,),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                        ),
                        onPressed: (){
                          setState(() {
                            searchName = searchController.text.trim();
                          });
                        },
                        child: Text(
                          "Search",
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index){
                      var user = filteredUsers[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                user['username'],
                                style: TextStyle(fontSize: 25,),
                              ),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[800],
                                ),
                                onPressed: (){
                                  showInformation({
                                    'username': user['username'],
                                    'email': user['email'],
                                    'gender': user['gender'],
                                    'cert_url': user['cert_url'],
                                  });
                                },
                                child: Text(
                                  "View Information",
                                  style: TextStyle(fontSize: 15, color: Colors.white),
                                ),
                              ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                          title: Text("Delete User"),
                                          content: Text("Are you sure you want to delete this user? \n\n${user['username']}"),
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
                                                    SnackBar(content: Text("User is deleted successfully.")),
                                                  );
                                                  await FirebaseFirestore.instance.collection('users').doc(user.id).delete();
                                                },
                                                child: Text("Yes", style: TextStyle(color: Colors.green[800], fontSize: 15),)
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Delete",
                                      style: TextStyle(fontSize: 15, color: Colors.white),
                                    ),
                                  ),

                                  SizedBox(width: 20,),

                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[800],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    onPressed: (){
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UpdateUser(userId: user.id, userData: user.data() as Map<String, dynamic>),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Update",
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
