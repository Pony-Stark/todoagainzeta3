import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import "routing.dart" as routing;
import "../task.dart";
import "../todos_data.dart";

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  dynamic selectedList = allListName;

  List<Widget> createSection(Section section, TodosData todosData) {
    var sectionTasks =
        todosData.getSection(section: section, selectedListID: selectedList);
    if (sectionTasks.length == 0) {
      return <Widget>[];
    }
    List<Widget> widgets = [
      Text(
        sectionToUIString(section),
        style: Theme.of(context).textTheme.subtitle1,
      ),
      SizedBox(height: 5),
    ];
    for (var task in sectionTasks) {
      widgets.add(ActivityCard(
        task: task,
        listName: todosData.activeLists[task.taskListID]!.listName,
      ));
    }
    widgets.add(SizedBox(height: 20));
    return widgets;
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
            leading: Icon(Icons.check_circle, size: 35),
            actions: [Icon(Icons.search, size: 30), Icon(Icons.menu, size: 30)],
            title: todosData.isDataLoaded
                ? DropdownButton<dynamic>(
                    iconEnabledColor: Theme.of(context).colorScheme.secondary,
                    underline: SizedBox(height: 0),
                    isExpanded: true,
                    items: () {
                      var activeLists = todosData.activeLists;
                      List<DropdownMenuItem<dynamic>> menuItems = [];
                      menuItems.add(DropdownMenuItem<String>(
                        child: Text(
                          allListName,
                          style: Theme.of(context).textTheme.subtitle2,
                        ),
                        value: allListName,
                      ));
                      for (var taskList in activeLists.values) {
                        menuItems.add(DropdownMenuItem<int>(
                          child: Text(
                            taskList.listName,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                          value: taskList.listID,
                        ));
                      }
                      return menuItems;
                    }(),
                    value: selectedList,
                    onChanged: (value) {
                      selectedList = value ?? selectedList;
                      setState(() {});
                    },
                  )
                : Text("Loading"),
          ),
          //body: function(s)
          body: () {
            {
              if (todosData.isDataLoaded) {
                List<Widget> children = [];

                for (var section in Section.values) {
                  var sectionWidgets = createSection(section, todosData);
                  children = [
                    ...children,
                    ...sectionWidgets,
                  ];
                }
                return ListView(
                  padding: const EdgeInsets.all(10),
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
    required this.task,
    required this.listName,
    Key? key,
  }) : super(key: key);

  final Task task;
  final String listName;

  String deadlineString(BuildContext context) {
    String deadlineDate = "";
    if (task.deadlineDate == null) {
      return "";
    } else {
      deadlineDate = DateFormat('EEEE, d MMM, yyyy').format(task.deadlineDate!);
      String deadlineTime = "";
      if (task.deadlineTime != null) {
        deadlineTime = task.deadlineTime!.format(context);
        return deadlineDate + ", " + deadlineTime;
      } else {
        return deadlineDate;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, routing.newTaskScreenID, arguments: task);
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Container(
          padding: EdgeInsets.all(10),
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Theme(
                  data: ThemeData(unselectedWidgetColor: Colors.white),
                  child: Checkbox(
                    onChanged: (value) {
                      Provider.of<TodosData>(context, listen: false)
                          .finishTask(task);
                    },
                    value: false,
                  ),
                ),
              ),
              Container(
                width: 10,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.taskName,
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                  SizedBox(height: 5),
                  ...(task.deadlineDate == null
                      ? []
                      : [
                          Text(
                            deadlineString(context),
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                        ]),
                  Text(listName),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
