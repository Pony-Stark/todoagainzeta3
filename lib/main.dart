import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/new_task_screen.dart';
import 'screens/routing.dart' as routing;
import "screens/home_screen.dart";
import 'sqlite.dart';
import "task.dart";
import "todos_data.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SqliteDB.initDb();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TodosData(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData.from(
          colorScheme: ColorScheme(
            brightness: Brightness.light,
            error: Colors.yellow,
            onError: Colors.black,
            background: Color(0xFF002C4F),
            onBackground: Colors.pink,
            primary: Color(0xFF016EAF),
            onPrimary: Colors.white,
            primaryVariant: Color(0xFF016EAF),
            secondary: Colors.white,
            secondaryVariant: Colors.green,
            onSecondary: Color(0xFF016EAF),
            surface: Color(0xFF005383),
            onSurface: Colors.white,
          ),
          textTheme: TextTheme(
            bodyText1: TextStyle(
              color: Color(0xFF85CDFD),
            ),
            bodyText2: TextStyle(
              color: Colors.white,
            ),
            subtitle1: TextStyle(
              color: Color(0xFF85CDFD),
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
            subtitle2: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 17,
            ),
            button: TextStyle(color: Colors.black),
          ),
        ),
        initialRoute: routing.homeScreenID,
        /*routes: {
          routing.newTaskScreenID: (context) => NewTaskScreen(),
          routing.homeScreenID: (context) => const MyHomePage(),
        },*/
        onGenerateRoute: (settings) {
          var pageName = settings.name;
          var args = settings.arguments;
          if (pageName == routing.newTaskScreenID) {
            if (args is Task) {
              return MaterialPageRoute(
                  builder: (context) => NewTaskScreen(task: args));
            }
            return MaterialPageRoute(builder: (context) => NewTaskScreen());
          }
          if (pageName == routing.homeScreenID)
            return MaterialPageRoute(builder: (context) => MyHomePage());
        },
      ),
    );
  }
}
