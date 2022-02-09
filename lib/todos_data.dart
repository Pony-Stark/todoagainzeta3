import 'package:flutter/cupertino.dart';
import 'task.dart';
import 'sqlite.dart';
import "package:firebase_auth/firebase_auth.dart";

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

  void initTodosData() async {
    now = DateTime.now();
    userID = FirebaseAuth.instance.currentUser!.uid;
    today = DateTime(now.year, now.month, now.day);
    nextMonth = DateTime(now.year, now.month, now.day + 30);

    activeTasks = await SqliteDB.getAllPendingTasks();
    activeLists = await SqliteDB.getAllActiveLists();
    for (var taskList in activeLists) {
      aggregatedTasksMap[taskList.listID] = AggregatedTasks();
    }
    activeTasks.sort((Task a, Task b) {
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
    });
    for (var task in activeTasks) {
      AggregatedTasks correctAggregatedTasks =
          aggregatedTasksMap[task.taskListID]!;
      if (task.deadlineDate == null)
        correctAggregatedTasks.later.add(task);
      else if (task.deadlineDate!.isAfter(nextMonth))
        correctAggregatedTasks.later.add(task);
      else {
        DateTime exactDeadline = task.deadlineDate!;
        if (task.deadlineTime == null)
          exactDeadline = DateTime(
              exactDeadline.year, exactDeadline.month, exactDeadline.day + 1);
        else
          exactDeadline = DateTime(
              exactDeadline.year,
              exactDeadline.month,
              exactDeadline.day + 1,
              task.deadlineTime!.hour,
              task.deadlineTime!.minute);
        if (now.isAfter(exactDeadline))
          correctAggregatedTasks.overdue.add(task);
        else
          correctAggregatedTasks.thisMonth.add(task);
      }
    }
    isDataLoaded = true;
    notifyListeners();
  }

  void addTask(Task task) async {
    var taskAsMap = task.toMap();
    taskAsMap.remove("taskID");
    int? id = await SqliteDB.insertTask(taskAsMap);
    if (id == null) {
      print("could not insert into database");
    } else {
      task.taskID = id;
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
    bool success = await SqliteDB.updateTask(task);
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
    bool success = await SqliteDB.deleteTask(task);
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
    SqliteDB.updateTask(task);
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
        TaskList(isActive: true, listID: -1, listName: listName);
    var taskListAsMap = taskList.toMap();
    taskListAsMap.remove("listID");
    int? id = await SqliteDB.insertList(taskListAsMap);
    if (id == null) {
      print("could not insert list into database");
    } else {
      taskList.listID = id;
      activeLists.add(taskList);
      notifyListeners();
    }
  }

  List<Task> fetchSection(
      {required int selectedListID, required Section section}) {
    AggregatedTasks correctAggregatedTasks =
        aggregatedTasksMap[selectedListID]!;
    if (section == Section.overdue) return correctAggregatedTasks.overdue;
    if (section == Section.thisMonth) return correctAggregatedTasks.thisMonth;
    if (section == Section.later)
      return correctAggregatedTasks.later;
    //TODO::throw error if you reach the following line
    else {
      print("we are in invalid state and throw some error");
      return [];
    }
  }
}
