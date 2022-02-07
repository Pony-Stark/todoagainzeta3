import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:provider/provider.dart';
import "routing.dart" as routing;
import "../sqlite.dart";
import "../task.dart";
import "../todos_data.dart";

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedListID = defaultListID;

  List<Widget> createSection(Section section, TodosData todosData) {
    List<Task> tasks = todosData.fetchSection(
        selectedListID: selectedListID, section: section);
    if (tasks.isEmpty) return [];
    List<Widget> sectionWidgets = [];
    sectionWidgets.add(Text(describeEnum(section)));
    sectionWidgets.add(SizedBox(height: 8));
    for (var task in tasks) {
      sectionWidgets.add(ActivityCard(
        task: task,
        header: task.taskName,
        date: task.deadlineDate == null ? "" : task.deadlineDate.toString(),
        list: task.taskListID.toString(),
        onTap: () {
          Navigator.pushNamed(context, routing.newTaskScreenID,
              arguments: task);
        },
      ));
    }
    return sectionWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodosData>(
      builder: (context, todosData, x) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            //onPressed: (){},
            child: const Icon(Icons.add, size: 35),
            onPressed: () {
              Navigator.pushNamed(context, routing.newTaskScreenID);
            },
          ),
          appBar: AppBar(
            title: DropdownButton<int>(
              isExpanded: true,
              //items: dropdownItemCreator(["Default"]),
              items: () {
                var activeLists = todosData.activeLists;
                List<DropdownMenuItem<int>> menuItems = [];
                for (var taskList in activeLists) {
                  menuItems.add(DropdownMenuItem<int>(
                    child: Text(taskList.listName),
                    value: taskList.listID,
                  ));
                }
                return menuItems;
              }(),
              value: selectedListID,
              onChanged: (value) {
                selectedListID = value ?? selectedListID;
                setState(() {});
              },
            ),
          ),
          //body: function(s)
          body: () {
            {
              if (todosData.isDataLoaded) {
                //var data = todosData.activeTasks;
                List<Widget> children = [];
                for (var section in Section.values) {
                  List<Widget> sectionWidgets =
                      createSection(section, todosData);
                  children = [...children, ...sectionWidgets];
                }
                return ListView(
                  padding: const EdgeInsets.all(5),
                  children: children,
                );
              } else {
                //if future has not returned
                return Center(child: CircularProgressIndicator());
              }
            }
          }(),
        );
      },
    );
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    required this.header,
    required this.date,
    required this.list,
    required this.onTap,
    required this.task,
    Key? key,
  }) : super(key: key);

  final String header, date, list;
  final void Function() onTap;
  final Task task;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  onChanged: (value) {
                    Provider.of<TodosData>(context, listen: false)
                        .finishTask(task);
                  },
                  value: false,
                ),
              ),
              Container(
                width: 10,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    header,
                    style: TextStyle(
                      //color, fontsize, fontweight
                      color: Colors.orange,
                      //fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(date),
                  Text(list),
                ],
              ),
            ],
          ),
        ),
        color: Colors.yellow,
      ),
    );
  }
}
