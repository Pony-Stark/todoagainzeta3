import 'package:flutter/cupertino.dart';
import 'task.dart';
import 'sqlite.dart';
import 'firestore_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  void deleteOriginalTask(Task task) {
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
  FirebaseAuth auth = FirebaseAuth.instance;
  bool isDataLoaded = false;
  List<Task> activeTasks = [];
  Map<String, TaskList> activeLists = {};
  Map<String, AggregatedTasks> aggregatedTasksMap = {};
  AggregatedTasks allListsCombined = AggregatedTasks();
  String userID = "";

  void initTodosData() async {
    //clear.. initTodosData may be called once user logs in
    isDataLoaded = false;
    activeTasks.clear();
    activeLists.clear();
    aggregatedTasksMap.clear();
    allListsCombined = AggregatedTasks();
    userID = auth.currentUser!.uid;

    activeTasks = (await FirestoreDB.getAllPendingTasks(userID))!;
    List<TaskList> activeListsAsArray = [
      TaskList(isActive: true, listID: defaultListID, listName: defaultListName)
    ];
    activeListsAsArray.addAll((await FirestoreDB.getAllActiveLists(userID))!);
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
    var taskAsMap = task.toFirestoreMap(userID);
    taskAsMap.remove("taskID");
    String? id = await FirestoreDB.insertTask(taskAsMap);
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
    bool success = await FirestoreDB.updateTask(task, userID);
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
          .deleteOriginalTask(originalTask);
      allListsCombined.deleteOriginalTask(originalTask);
      aggregatedTasksMap[task.taskListID]!.insertTask(task);
      allListsCombined.insertTask(task);
    }
    notifyListeners();
  }

  void deleteTask(Task task) async {
    //task variable may have been modified before deleting
    bool success = await FirestoreDB.deleteTask(task);
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
          .deleteOriginalTask(originalTask);
      allListsCombined.deleteOriginalTask(originalTask);
      notifyListeners();
    }
  }

  void finishTask(Task task) async {
    task.isFinished = true;
    FirestoreDB.updateTask(task, userID);
    var index = _findTaskIndexInActiveTaskList(task);
    activeTasks.removeAt(index!);
    aggregatedTasksMap[task.taskListID]!.deleteOriginalTask(task);
    allListsCombined.deleteOriginalTask(task);
    notifyListeners();
  }

  void addList(String listName) async {
    TaskList taskList =
        TaskList(isActive: true, listID: "-1", listName: listName);
    var taskListAsMap = taskList.toFirestoreMap(userID);
    taskListAsMap.remove("listID");
    String? id = await FirestoreDB.insertList(taskListAsMap);
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
      {required Section section, required String selectedListID}) {
    AggregatedTasks selectedAggregatedTasks;
    if (selectedListID == allListName)
      selectedAggregatedTasks = allListsCombined;
    else if (selectedListID == selectedListID)
      selectedAggregatedTasks = aggregatedTasksMap[selectedListID]!;
    else {
      print("no such list. Wrong input parameter");
      return [];
    }
    return selectedAggregatedTasks.findListFromSection(section);
  }
}
