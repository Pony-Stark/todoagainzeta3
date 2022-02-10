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

class _LogoScreenState extends State<LogoScreen> {
  @override
  initState() {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
      await Firebase.initializeApp();
      FirebaseAuth auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        Provider.of<TodosData>(context, listen: false).initTodosData();
        Navigator.pushNamedAndRemoveUntil(
            context, routing.homeScreenID, (route) => false);
      } else
        Navigator.pushNamedAndRemoveUntil(
            context, routing.socialSignInID, (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Todos"));
  }
}
