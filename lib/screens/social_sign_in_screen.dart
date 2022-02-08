import "package:flutter/material.dart";
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
                  child: Text("Print user's sign in state"),
                  onPressed: () {
                    var x = auth.currentUser;
                    if (x != null) {
                      print(x.emailVerified);
                    } else {
                      print("User not signed in");
                    }
                  }),
              TextButton(
                  child: Text("Send email verification"),
                  onPressed: () async {
                    var x = auth.currentUser;
                    if (x != null) {
                      await x.sendEmailVerification();
                    } else {
                      print("User not signed in");
                    }
                  }),
              TextButton(
                  child: Text("Log out"),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  }),
              TextButton(
                child: Text("Sign Up"),
                onPressed: () async {
                  try {
                    UserCredential userCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                            email: "shubhamjalan1729@gmail.com",
                            password: "abcd1234xyzpqrs");
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'weak-password') {
                      print('The password provided is too weak.');
                    } else if (e.code == 'email-already-in-use') {
                      print('The account already exists for that email.');
                    }
                  } catch (e) {
                    print(e);
                  }

                  /*await FirebaseAuth.instance
                      .signInWithCredential(userCredential);*/
                },
              ),
              TextButton(
                child: Text("Sign In"),
                onPressed: () async {
                  try {
                    UserCredential userCredential = await FirebaseAuth.instance
                        .signInWithEmailAndPassword(
                            email: "shubhamjalan1729@gmail.com",
                            password: "abcd1234xyzpqrs");
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'weak-password') {
                      print('The password provided is too weak.');
                    } else if (e.code == 'email-already-in-use') {
                      print('The account already exists for that email.');
                    } else
                      print(e.code);
                  } catch (e) {
                    print(e);
                  }

                  /*await FirebaseAuth.instance
                      .signInWithCredential(userCredential);*/
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}
