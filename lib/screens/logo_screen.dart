import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:todoagainzeta3/todos_data.dart';
import 'routing.dart' as routing;
import "../sqlite.dart";
import "social_sign_in_screen.dart";
import "home_screen.dart";

class LogoScreen extends StatefulWidget {
  const LogoScreen({Key? key}) : super(key: key);

  @override
  _LogoScreenState createState() => _LogoScreenState();
}

Future<int> initialization() async {
  await Firebase.initializeApp();
  await SqliteDB.initDb();
  return 1;
}

class _LogoScreenState extends State<LogoScreen> {
  Future<int> init = initialization();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: init,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          FirebaseAuth auth = FirebaseAuth.instance;
          if (auth.currentUser == null) {
            Provider.of<TodosData>(context, listen: false).initTodosData();
            return SocialSignIn();
          } else
            return MyHomePage();
        } else if (snapshot.hasError)
          return Center(child: (Text("Error")));
        else
          return Center(child: CircularProgressIndicator());
      },
    );
  }
}
