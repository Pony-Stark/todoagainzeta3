import 'package:flutter/cupertino.dart';
import 'task.dart';
import 'sqlite.dart';
import "package:firebase_auth/firebase_auth.dart";
import "firestore_wrapper.dart";

class AggregatedTasks {
  List<Task> overdue = [], thisMonth = [], later = [];
}

enum Section {
  overdue,
  thisMonth,
  later,
}

class TodosData extends ChangeNotifier {
  bool isDataLoaded = false;
  List<Task> activeTasks = [];
  List<TaskList> activeLists = [];
  Map<int, AggregatedTasks> aggregatedTasksMap = {};
  DateTime now = DateTime.now();
  DateTime today = DateTime.now();
  DateTime nextMonth = DateTime.now();
  String userID = "";

  int compareTasksByDeadline(Task a, Task b) {
    if (a.deadlineDate == null) return 1;
    if (b.deadlineDate == null) return -1;
    if (a.deadlineDate!.isAfter(b.deadlineDate!)) return 1;
    if (b.deadlineDate!.isAfter(a.deadlineDate!)) return -1;
    //both a and b are on same dates
    if (a.deadlineTime == null) return 1;
    if (b.deadlineTime == null) return -1;
    if (intFromTimeOfDay(a.deadlineTime!) > intFromTimeOfDay(b.deadlineTime!))
      return 1;
    if (intFromTimeOfDay(a.deadlineTime!) < intFromTimeOfDay(b.deadlineTime!))
      return -1;
    return 0;
  }

  Section findSectionForTask(Task task) {
    if (task.deadlineDate == null)
      return Section.later;
    else if (task.deadlineDate!.isAfter(nextMonth))
      return Section.later;
    else {
      DateTime exactDeadline = task.deadlineDate!;
      if (task.deadlineTime == null)
        exactDeadline = DateTime(
            exactDeadline.year, exactDeadline.month, exactDeadline.day + 1);
      else
        exactDeadline = DateTime(
            exactDeadline.year,
            exactDeadline.month,
            exactDeadline.day,
            task.deadlineTime!.hour,
            task.deadlineTime!.minute);
      if (now.isAfter(exactDeadline))
        return Section.overdue;
      else
        return Section.thisMonth;
    }
  }

  void initTodosData() async {
    now = DateTime.now();
    userID = FirebaseAuth.instance.currentUser!.uid;
    today = DateTime(now.year, now.month, now.day);
    nextMonth = DateTime(now.year, now.month, now.day + 30);
    userID = FirebaseAuth.instance.currentUser!.uid;

    activeLists = [
      TaskList(isActive: true, listID: defaultListID, listName: defaultListName)
    ];
    activeTasks = (await FirestoreDB.getAllPendingTasks(userID))!;
    activeLists.addAll((await FirestoreDB.getAllActiveLists(userID))!);
    activeTasks.sort(compareTasksByDeadline);
    isDataLoaded = true;
    notifyListeners();
  }

  void addTask(Task task) async {
    var taskAsMap = task.toMap();
    taskAsMap.remove("taskID");
    taskAsMap["uid"] = userID;
    //int? id = await SqliteDB.insertTask(taskAsMap);
    String? id = await FirestoreDB.insertTask(taskAsMap);
    if (id == null) {
      print("could not insert into database");
    } else {
      task.taskID = id.toString();
      activeTasks.add(task);
      notifyListeners();
    }
  }

  int? findTaskIndexInActiveTaskList(Task task) {
    var index = activeTasks.indexWhere((Task t) {
      return t.taskID == task.taskID;
    });

    if (index == -1) return null;
    return index;
  }

  void updateTask(Task task) async {
    bool success = await FirestoreDB.updateTask(task, userID);
    if (success == false) {
      print("could not update the task");
    }
    {
      var index = findTaskIndexInActiveTaskList(task);
      if (index != null)
        activeTasks[index] = task;
      else {
        print("task not found in active task list");
      }
    }
    notifyListeners();
  }

  void deleteTask(Task task) async {
    bool success = await FirestoreDB.deleteTask(task);
    if (success == false) {
      print("Could not delete task");
    } else {
      var index = findTaskIndexInActiveTaskList(task);
      if (index != null) {
        activeTasks.removeAt(index);
        notifyListeners();
      } else {
        print("task not found in active task list");
      }
    }
  }

  void finishTask(Task task) async {
    task.isFinished = true;
    FirestoreDB.updateTask(task, userID);
    var index = findTaskIndexInActiveTaskList(task);
    if (index == null) {
      print("Task not found in active task list");
    } else {
      activeTasks.removeAt(index);
      notifyListeners();
    }
  }

  void addList(String listName) async {
    TaskList taskList =
        TaskList(isActive: true, listID: "-1", listName: listName);
    var taskListAsMap = taskList.toMap();
    taskListAsMap.remove("listID");
    taskListAsMap["uid"] = userID;
    String? id = await FirestoreDB.insertList(taskListAsMap);
    if (id == null) {
      print("could not insert list into database");
    } else {
      taskList.listID = id;
      activeLists.add(taskList);
      notifyListeners();
    }
  }

  List<Task> fetchSection(
      {required String selectedListID, required Section section}) {
    List<Task> result = [];
    activeTasks.sort(compareTasksByDeadline);
    for (var task in activeTasks) {
      if (task.taskListID != selectedListID) continue;
      Section taskSection = findSectionForTask(task);
      if (taskSection == section) result.add(task);
    }
    return result;
  }
}
