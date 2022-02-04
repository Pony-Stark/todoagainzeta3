import 'package:flutter/cupertino.dart';
import 'task.dart';
import 'sqlite.dart';

class AggregatedTasks {
  TaskList taskList;
  List<Task> overdue = [],
      today = [],
      thisWeek = [],
      thisMonth = [],
      noDeadLine = [];
  AggregatedTasks({required this.taskList});
}

class TodosData extends ChangeNotifier {
  bool isDataLoaded = false;
  List<Task> activeTasks = [];
  TodosData() {
    initTodosData();
  }
  List<TaskList> activeLists = [];
  Map<int, AggregatedTasks> aggregatedTasksMap = {};
  void initTodosData() async {
    activeTasks = await SqliteDB.getAllPendingTasks();
    activeLists = await SqliteDB.getAllActiveLists();
    for (var taskList in activeLists) {
      aggregatedTasksMap[taskList.listID] = AggregatedTasks(taskList: taskList);
    }
    activeTasks.sort();
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
}
