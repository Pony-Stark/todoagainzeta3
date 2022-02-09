import "package:flutter/material.dart";
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../todos_data.dart';
import "routing.dart" as routing;

class SocialSignIn extends StatefulWidget {
  const SocialSignIn({Key? key}) : super(key: key);

  @override
  _SocialSignInState createState() => _SocialSignInState();
}

class _SocialSignInState extends State<SocialSignIn> {
  FirebaseAuth auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: (context) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: Text("Google sign in"),
                onPressed: () async {
                  try {
                    final GoogleSignInAccount? googleUser =
                        await GoogleSignIn().signIn();
                    final GoogleSignInAuthentication? googleAuth =
                        await googleUser?.authentication;

                    // Create a new credential
                    final credential = GoogleAuthProvider.credential(
                      accessToken: googleAuth!.accessToken,
                      idToken: googleAuth!.idToken,
                    );

                    // Once signed in, return the UserCredential
                    await FirebaseAuth.instance
                        .signInWithCredential(credential);
                    Provider.of<TodosData>(context, listen: false)
                        .initTodosData();
                    Navigator.pushNamedAndRemoveUntil(
                        context, routing.homeScreenID, (route) => false);
                  } catch (e) {
                    print(e);
                  }
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}
