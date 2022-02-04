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
        theme: ThemeData(
          primarySwatch: Colors.red,
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
