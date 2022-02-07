import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:intl/intl.dart';
import '../task.dart';
import '../sqlite.dart';
import 'routing.dart' as routing;
import 'package:provider/provider.dart';
import "../todos_data.dart";

class NewTaskScreen extends StatefulWidget {
  NewTaskScreen({Key? key, this.task}) : super(key: key);
  final Task? task;
  @override
  _NewTaskScreenState createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  Task task = Task(
      isFinished: false,
      isRepeating: false,
      taskName: "",
      taskListID: defaultListID,
      taskID: -1,
      parentTaskID: null,
      deadlineDate: null,
      deadlineTime: null);
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  RepeatCycle? chosenRepeatCycle;
  RepeatFrequency repeatFrequency =
      RepeatFrequency(num: 2, tenure: Tenure.days);

  /*@override
  initState() {
    super.initState();
  }*/

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    task = widget.task ?? task;
    dateController.text = task.deadlineDate == null
        ? ""
        : DateFormat('EEEE, d MMM, yyyy').format(task.deadlineDate!);
    timeController.text =
        task.deadlineTime == null ? "" : task.deadlineTime!.format(context);
    nameController.text = task.taskName;
  }

  void datePicker() async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate:
            task.deadlineDate == null ? DateTime.now() : task.deadlineDate!,
        firstDate: DateTime.now(),
        //TODO::lastDate should be 50/100/x number of years from now
        lastDate: DateTime(2101));
    if (pickedDate != null) {
      task.deadlineDate = pickedDate;
      setState(() {});
      var dateString = DateFormat('EEEE, d MMM, yyyy').format(pickedDate);
      dateController.text = dateString;
    }
  }

  void timePicker() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      task.deadlineTime = pickedTime;
      setState(() {});
      timeController.text = pickedTime.format(context);
    }
  }

  List<DropdownMenuItem<String>> dropdownItemCreator(List<String> itemValues) {
    List<DropdownMenuItem<String>> dropdownMenuItems = [];
    for (var i = 0; i < itemValues.length; i++) {
      dropdownMenuItems.add(
        DropdownMenuItem<String>(
          value: itemValues[i],
          child: Text(itemValues[i]),
        ),
      );
    }
    return dropdownMenuItems;
  }

  void saveNewTask() async {
    Provider.of<TodosData>(context, listen: false).addTask(task);
    Navigator.pop(context);
  }

  void updateTask() async {
    Provider.of<TodosData>(context, listen: false).updateTask(task);
    Navigator.pop(context);
  }

  void deleteTask() async {
    Provider.of<TodosData>(context, listen: false).deleteTask(task);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.check,
          size: 35,
        ),
        onPressed: () {
          if (widget.task == null)
            saveNewTask();
          else
            updateTask();
        },
      ),
      appBar: AppBar(
        title: Text(widget.task == null ? "New Task" : "Edit Task"),
        actions: widget.task != null
            ? [
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: deleteTask,
                )
              ]
            : [],
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Task details
            Text(
              "What is to be done?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                SizedBox(width: 10),
                Flexible(
                  child: TextField(
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(0, 10, 0, 5),
                      isDense: true,
                      hintText: "Enter Task Here",
                    ),
                    controller: nameController,
                    onChanged: (String? value) {
                      task.taskName = value == null ? task.taskName : value;
                    },
                  ),
                ),
                CustomIconButton(iconData: Icons.mic, onPressed: () {}),
              ],
            ),
            SizedBox(
              height: 50,
            ),

            //Date Time Input
            Text(
              "Due Date",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 10),
            EditableFieldWithCancelButton(
              hintText: "Date not set",
              iconData: Icons.calendar_today_outlined,
              textController: dateController,
              picker: datePicker,
              onCancel: () {
                task.deadlineDate = null;
                dateController.text = "";
                task.deadlineTime = null;
                timeController.text = "";
                setState(() {});
              },
              enableCancelButton: () {
                return (task.deadlineDate != null);
              },
            ),

            //Time Input
            SizedBox(height: 10),
            Visibility(
              visible: task.deadlineDate != null ? true : false,
              child: EditableFieldWithCancelButton(
                hintText: "Time not set",
                iconData: Icons.access_time,
                textController: timeController,
                picker: timePicker,
                onCancel: () {
                  task.deadlineTime = null;
                  setState(() {});
                  timeController.text = "";
                },
                enableCancelButton: () {
                  return (task.deadlineTime != null);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Notifications",
                  ),
                  SizedBox(height: 4),
                  Text(
                    task.deadlineDate != null
                        ? "Day summary on the same day at 8:00 am."
                        : "No notifications if date not set",
                  ),
                  SizedBox(height: 4),
                  Visibility(
                    child: Text(
                      "Individual notification on time",
                    ),
                    visible: task.deadlineTime != null,
                  ),
                ],
              ),
            ),

            //Repeating Info
            const SizedBox(height: 40),
            Text(
              "Repeat",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Row(
              children: [
                SizedBox(width: 10),
                DropdownButton<dynamic>(
                  items: () {
                    List<DropdownMenuItem<dynamic>> items = [];
                    items.add(const DropdownMenuItem<dynamic>(
                      child: Text(
                        noRepeat,
                      ),
                      value: noRepeat,
                    ));
                    for (var value in RepeatCycle.values) {
                      items.add(DropdownMenuItem<dynamic>(
                        child: Text(
                          repeatCycleToUIString(value),
                        ),
                        value: value,
                      ));
                    }

                    //values.add(noRepeat);
                    return (items);
                  }(),
                  value: chosenRepeatCycle ?? noRepeat,
                  onChanged: (dynamic chosenValue) {
                    if (chosenValue != null) {
                      if (chosenValue == noRepeat)
                        chosenRepeatCycle = null;
                      else
                        chosenRepeatCycle = chosenValue;
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
            Visibility(
              visible: chosenRepeatCycle == RepeatCycle.other,
              child: Column(children: [
                SizedBox(height: 10),
                Row(children: [
                  SizedBox(width: 10),
                  DropdownButton<int>(
                    items: [2, 3, 4, 5, 6, 7, 8, 9, 10]
                        .map((int t) => DropdownMenuItem<int>(
                              child: Text(t.toString()),
                              value: t,
                            ))
                        .toList(),
                    value: repeatFrequency.num,
                    onChanged: (value) {
                      if (value != null) {
                        repeatFrequency.num = value;
                        setState(() {});
                      }
                    },
                  ),
                  SizedBox(width: 10),
                  DropdownButton<Tenure>(
                    items: Tenure.values
                        .map((Tenure t) => DropdownMenuItem<Tenure>(
                              child: Text(describeEnum(t)),
                              value: t,
                            ))
                        .toList(),
                    value: repeatFrequency.tenure,
                    onChanged: (value) {
                      if (value != null) {
                        repeatFrequency.tenure = value;
                        setState(() {});
                      }
                    },
                  )
                ])
              ]),
            ),

            //Select taskList
            const SizedBox(height: 40),
            Text(
              "Select a List",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 5),
            Row(
              children: [
                SizedBox(width: 10),
                //dropdown Menu for list
                Consumer<TodosData>(builder: (context, todosData, child) {
                  return Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      //items: dropdownItemCreator(["Default"]),
                      items: () {
                        var activeLists = todosData.activeLists;
                        List<DropdownMenuItem<int>> menuItems = [];
                        for (var taskList in activeLists.values) {
                          menuItems.add(DropdownMenuItem<int>(
                            child: Text(taskList.listName),
                            value: taskList.listID,
                          ));
                        }
                        return menuItems;
                      }(),
                      value: task.taskListID,
                      onChanged: (value) {
                        task.taskListID = value ?? task.taskListID;
                        setState(() {});
                      },
                    ),
                  );
                }),
                SizedBox(width: 5),
                CustomIconButton(
                  iconData: Icons.playlist_add_outlined,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        String listName = "";
                        return AlertDialog(
                          title: Text("Add New list"),
                          content: TextField(
                            decoration: InputDecoration(
                              hintText: "Enter name of new list",
                            ),
                            onChanged: (value) {
                              listName = value;
                              setState(() {});
                            },
                          ),
                          actions: <Widget>[
                            TextButton(
                                child: Text("OK"),
                                onPressed: () {
                                  //TODO::make the button inactive when string is empty
                                  Provider.of<TodosData>(context, listen: false)
                                      .addList(listName);
                                  Navigator.pop(context);
                                }),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EditableFieldWithCancelButton extends StatelessWidget {
  const EditableFieldWithCancelButton({
    Key? key,
    required this.hintText,
    required this.iconData,
    required this.textController,
    required this.picker,
    required this.onCancel,
    required this.enableCancelButton,
  }) : super(key: key);

  final String hintText;
  final IconData iconData;
  final TextEditingController textController;
  final void Function() picker;
  final void Function() onCancel;
  final bool Function() enableCancelButton;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 5),
        Flexible(
          child: TextField(
            controller: textController,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(0, 10, 0, 5),
              isDense: true,
              hintText: hintText,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white60,
                ),
              ),
            ),
            onTap: picker,
            enableInteractiveSelection: false,
            showCursor: false,
            readOnly: true,
          ),
        ),
        SizedBox(width: 5),
        CustomIconButton(
          iconData: iconData,
          onPressed: picker,
        ),
        Visibility(
            child: CustomIconButton(
              iconData: Icons.cancel_rounded,
              onPressed: onCancel,
            ),
            visible: enableCancelButton()),
      ],
    );
  }
}

class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    required this.iconData,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  final IconData iconData;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
      ),
      child: Icon(iconData),
      onPressed: onPressed,
    );
  }
}
