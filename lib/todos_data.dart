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
  static DateTime nowTime = DateTime.now();
  static DateTime todayDate = DateTime.now();
  static DateTime tomorrowDate = DateTime.now();
  static DateTime nextWeekDate = DateTime.now();
  static DateTime nextMonthDate = DateTime.now();
  static void initializeDateVars() {
    nowTime = DateTime.now();
    todayDate = DateTime(nowTime.year, nowTime.month, nowTime.day);
    tomorrowDate = DateTime(nowTime.year, nowTime.month, nowTime.day + 1);
    nextWeekDate = DateTime(nowTime.year, nowTime.month, nowTime.day + 7);
    nextMonthDate = DateTime(nowTime.year, nowTime.month, nowTime.day + 30);
  }

  static int deadlineComparator(Task a, Task b) {
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
  }

  Section findSection(Task task) {
    if (task.deadlineDate == null) {
      return Section.noDeadline;
    } else if (task.deadlineDate!.isAfter(nextMonthDate)) {
      return Section.later;
    } else if (task.deadlineDate!.isAfter(nextWeekDate)) {
      return Section.thisMonth;
    } else if (task.deadlineDate!.isAfter(tomorrowDate)) {
      return Section.thisWeek;
    } else if (task.deadlineDate!.isAfter(todayDate)) {
      return Section.tomorrow;
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
      if (accurateDeadline.isAfter(nowTime)) {
        return Section.today;
      } else {
        return Section.overdue;
      }
    }
  }

  List<Task> findListFromSection(Section section) {
    List<Task> targetList;
    if (section == Section.noDeadline) {
      targetList = noDeadLine;
    } else if (section == Section.later) {
      targetList = later;
    } else if (section == Section.thisMonth) {
      targetList = thisMonth;
    } else if (section == Section.thisWeek) {
      targetList = thisWeek;
    } else if (section == Section.tomorrow) {
      targetList = tomorrow;
    } else if (section == Section.today) {
      targetList = today;
    } else {
      //TODO:: handle the error
      assert(section == Section.overdue);
      targetList = overdue;
    }
    return targetList;
  }

  void insertTask(Task task) {
    Section section = findSection(task);
    List<Task> targetList = findListFromSection(section);
    int index = targetList
        .indexWhere((element) => deadlineComparator(element, task) == 1);
    if (index == -1)
      targetList.add(task);
    else
      targetList.insert(index, task);
  }

  //to be used if tasks being inserted are already sorted
  void insertTaskInitialization(Task task) {
    Section section = findSection(task);
    List<Task> targetList = findListFromSection(section);
    targetList.add(task);
  }

  void deleteUnmodifiedTask(Task task) {
    Section section = findSection(task);
    List<Task> targetList = findListFromSection(section);
    int index =
        targetList.indexWhere((element) => element.taskID == task.taskID);
    assert(index != -1, "Task must exist");
    targetList.removeAt(index);
  }

  // void deleteModifiedTask(Task task) {
  //   for (List<Task> taskList in [
  //     overdue,
  //     today,
  //     tomorrow,
  //     thisWeek,
  //     thisMonth,
  //     later,
  //     noDeadLine
  //   ]) {
  //     int index =
  //         taskList.indexWhere((element) => element.taskID == task.taskID);
  //     if (index != -1) {
  //       taskList.removeAt(index);
  //       return;
  //     }
  //   }
  //   assert(1 == 0, "it should be present somewhere");
  // }
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

String sectionToUIString(Section section) {
  Map<Section, String> mapper = {
    Section.overdue: "Overdue",
    Section.today: "Today",
    Section.tomorrow: "Tomorrow",
    Section.thisWeek: "This Week",
    Section.thisMonth: "This Month",
    Section.later: "Later",
    Section.noDeadline: "No Deadline",
  };
  return (mapper[section]!);
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

  void initTodosData() async {
    //activeTasks sorted initially. But not when user inserts/updates a task
    activeTasks = await SqliteDB.getAllPendingTasks();
    var activeListsAsArray = await SqliteDB.getAllActiveLists();
    AggregatedTasks.initializeDateVars();
    for (var taskList in activeListsAsArray) {
      activeLists[taskList.listID] = taskList;
      aggregatedTasksMap[taskList.listID] = AggregatedTasks();
    }
    activeTasks.sort(AggregatedTasks.deadlineComparator);
    for (var task in activeTasks) {
      var listId = task.taskListID;
      aggregatedTasksMap[listId]!.insertTaskInitialization(task);
      allListsCombined.insertTaskInitialization(task);
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
      aggregatedTasksMap[task.taskListID]!.insertTask(task);
      allListsCombined.insertTask(task);
      notifyListeners();
    }
  }

  int? _findTaskIndexInActiveTaskList(Task task) {
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
      var index = _findTaskIndexInActiveTaskList(task);
      assert(index != null, "task not found in active task list");
      Task originalTask = activeTasks[index!];
      activeTasks[index!] = task;
      //print(originalTask.deadlineDate);
      //crucial to remove originalTask taskListID, modified task task list ID may be different
      aggregatedTasksMap[originalTask.taskListID]!
          .deleteUnmodifiedTask(originalTask);
      allListsCombined.deleteUnmodifiedTask(originalTask);
      aggregatedTasksMap[task.taskListID]!.insertTask(task);
      allListsCombined.insertTask(task);
    }
    notifyListeners();
  }

  void deleteTask(Task task) async {
    //task variable may have been modified before deleting
    bool success = await SqliteDB.deleteTask(task);
    if (success == false) {
      print("Could not delete task");
    } else {
      var index = _findTaskIndexInActiveTaskList(task);
      assert(index != null, "task not found in active task list");
      Task originalTask = activeTasks[index!];
      activeTasks.removeAt(index!);
      //print(originalTask.deadlineDate);
      //crucial to remove originalTask taskListID, modified task task list ID may be different
      aggregatedTasksMap[originalTask.taskListID]!
          .deleteUnmodifiedTask(originalTask);
      allListsCombined.deleteUnmodifiedTask(originalTask);
      notifyListeners();
    }
  }

  void finishTask(Task task) async {
    task.isFinished = true;
    SqliteDB.updateTask(task);
    var index = _findTaskIndexInActiveTaskList(task);
    activeTasks.removeAt(index!);
    aggregatedTasksMap[task.taskListID]!.deleteUnmodifiedTask(task);
    allListsCombined.deleteUnmodifiedTask(task);
    notifyListeners();
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
      aggregatedTasksMap[id] = AggregatedTasks();
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
