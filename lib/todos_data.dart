import 'package:flutter/cupertino.dart';
import 'task.dart';
import 'sqlite.dart';

class AggregatedTasks {
  List<Task> overdue = [],
      today = [],
      tomorrow = [],
      thisWeek = [],
      thisMonth = [],
      later = [],
      noDeadLine = [];
}

enum Section {
  overdue,
  today,
  tomorrow,
  thisWeek,
  thisMonth,
  later,
  noDeadline,
}

class TodosData extends ChangeNotifier {
  bool isDataLoaded = false;
  List<Task> activeTasks = [];
  TodosData() {
    initTodosData();
  }
  Map<int, TaskList> activeLists = {};
  Map<int, AggregatedTasks> aggregatedTasksMap = {};
  AggregatedTasks allListsCombined = AggregatedTasks();
  DateTime now = DateTime.now();
  DateTime today = DateTime.now();
  DateTime tomorrow = DateTime.now();
  DateTime nextWeek = DateTime.now();
  DateTime nextMonth = DateTime.now();

  void initializeDateVars() {
    now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    tomorrow = DateTime(now.year, now.month, now.day + 1);
    nextWeek = DateTime(now.year, now.month, now.day + 7);
    nextMonth = DateTime(now.year, now.month, now.day + 30);
  }

  void initTodosData() async {
    //activeTasks sorted initially. But not when user inserts/updates a task
    activeTasks = await SqliteDB.getAllPendingTasks();
    var activeListsAsArray = await SqliteDB.getAllActiveLists();
    initializeDateVars();
    for (var taskList in activeListsAsArray) {
      activeLists[taskList.listID] = taskList;
      aggregatedTasksMap[taskList.listID] = AggregatedTasks();
    }
    activeTasks.sort((a, b) {
      if (a.deadlineDate == null)
        return 1;
      else if (b.deadlineDate == null)
        return -1;
      else if (a.deadlineDate!.isAfter(b.deadlineDate!))
        return 1;
      else if (b.deadlineDate!.isAfter(a.deadlineDate!)) return -1;
      if (a.deadlineTime == null)
        return 1;
      else if (b.deadlineTime == null)
        return -1;
      else if (intFromTimeOfDay(a.deadlineTime!) >
          intFromTimeOfDay(a.deadlineTime!))
        return 1;
      else if (intFromTimeOfDay(a.deadlineTime!) <
          intFromTimeOfDay(a.deadlineTime!))
        return -1;
      else
        return 0;
    });
    for (var task in activeTasks) {
      var listId = task.taskListID;
      if (task.deadlineDate == null) {
        aggregatedTasksMap[listId]!.noDeadLine.add(task);
        allListsCombined.noDeadLine.add(task);
      } else if (task.deadlineDate!.isAfter(nextMonth)) {
        aggregatedTasksMap[listId]!.later.add(task);
        allListsCombined.later.add(task);
      } else if (task.deadlineDate!.isAfter(nextWeek)) {
        aggregatedTasksMap[listId]!.thisMonth.add(task);
        allListsCombined.thisMonth.add(task);
      } else if (task.deadlineDate!.isAfter(tomorrow)) {
        aggregatedTasksMap[listId]!.thisWeek.add(task);
        allListsCombined.thisWeek.add(task);
      } else if (task.deadlineDate!.isAfter(today)) {
        aggregatedTasksMap[listId]!.tomorrow.add(task);
        allListsCombined.tomorrow.add(task);
      } else {
        DateTime accurateDeadline = task.deadlineDate!;
        if (task.deadlineTime == null)
          accurateDeadline = DateTime(
            accurateDeadline.year,
            accurateDeadline.month,
            accurateDeadline.day + 1,
          );
        else
          accurateDeadline = DateTime(
            accurateDeadline.year,
            accurateDeadline.month,
            accurateDeadline.day,
            task.deadlineTime!.hour,
            task.deadlineTime!.minute,
          );
        if (accurateDeadline.isAfter(now)) {
          aggregatedTasksMap[listId]!.today.add(task);
          allListsCombined.today.add(task);
        } else {
          aggregatedTasksMap[listId]!.overdue.add(task);
          allListsCombined.overdue.add(task);
        }
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
      activeLists[id] = taskList;
      notifyListeners();
    }
  }

  List<Task> getSection(
      {required Section section, required dynamic selectedListID}) {
    AggregatedTasks selectedAggregatedTasks;
    if (selectedListID is int)
      selectedAggregatedTasks = aggregatedTasksMap[selectedListID]!;
    else if (selectedListID is String && selectedListID == allListName)
      selectedAggregatedTasks = allListsCombined;
    else {
      print("no such list. Wrong input parameter");
      return [];
    }

    if (section == Section.overdue)
      return selectedAggregatedTasks.overdue;
    else if (section == Section.today)
      return selectedAggregatedTasks.today;
    else if (section == Section.tomorrow)
      return selectedAggregatedTasks.tomorrow;
    else if (section == Section.thisWeek)
      return selectedAggregatedTasks.thisWeek;
    else if (section == Section.thisMonth)
      return selectedAggregatedTasks.thisMonth;
    else if (section == Section.later)
      return selectedAggregatedTasks.later;
    else if (section == Section.noDeadline)
      return selectedAggregatedTasks.noDeadLine;
    else {
      //TODO::Throw error if execution reaches here
      print("this condition is not possible. Throw error");
      return [];
    }
  }
}
