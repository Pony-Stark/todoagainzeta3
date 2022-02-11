import 'package:flutter/cupertino.dart';
import 'task.dart';
import 'firestore_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskListData {
  List<Task> overdue = [],
      today = [],
      tomorrow = [],
      thisWeek = [],
      thisMonth = [],
      later = [],
      noDeadLine = [];

  Section _findSection(Task task) {
    if (task.deadlineDate == null) {
      return Section.noDeadline;
    } else if (task.deadlineDate!.isAfter(TodosData.nextMonthDate!)) {
      return Section.later;
    } else if (task.deadlineDate!.isAfter(TodosData.nextWeekDate!)) {
      return Section.thisMonth;
    } else if (task.deadlineDate!.isAfter(TodosData.tomorrowDate!)) {
      return Section.thisWeek;
    } else if (task.deadlineDate!.isAfter(TodosData.todayDate!)) {
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
      if (accurateDeadline.isAfter(TodosData.nowTime!)) {
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
    Section section = _findSection(task);
    List<Task> targetList = findListFromSection(section);
    int index = targetList
        .indexWhere((element) => Task.deadlineComparator(element, task) == 1);
    if (index == -1)
      targetList.add(task);
    else
      targetList.insert(index, task);
  }

  //to be used if tasks being inserted are already sorted
  void insertTaskInitialization(Task task) {
    Section section = _findSection(task);
    List<Task> targetList = findListFromSection(section);
    targetList.add(task);
  }

  void deleteOriginalTask(Task task) {
    Section section = _findSection(task);
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
  static DateTime? nowTime;
  static DateTime? todayDate;
  static DateTime? tomorrowDate;
  static DateTime? nextWeekDate;
  static DateTime? nextMonthDate;
  static void initializeDateVars() {
    nowTime = DateTime.now();
    todayDate = DateTime(nowTime!.year, nowTime!.month, nowTime!.day);
    tomorrowDate = DateTime(nowTime!.year, nowTime!.month, nowTime!.day + 1);
    nextWeekDate = DateTime(nowTime!.year, nowTime!.month, nowTime!.day + 7);
    nextMonthDate = DateTime(nowTime!.year, nowTime!.month, nowTime!.day + 30);
  }

  FirebaseAuth auth = FirebaseAuth.instance;
  bool isDataLoaded = false;
  List<Task> activeTasks = [];
  Map<String, TaskList> activeLists = {};
  Map<String, TaskListData> allTaskListData = {};
  TaskListData allListsCombined = TaskListData();
  Map<String, RepeatingTask> activeRepeatingTasks = {};
  String userID = "";

  void initTodosData() async {
    //clear.. initTodosData may be called once user logs in
    _flushData();
    userID = auth.currentUser!.uid;

    initializeDateVars();

    activeTasks = (await FirestoreDB.getAllPendingTasks(userID))!;
    List<TaskList> activeListsAsArray = [
      TaskList(isActive: true, listID: defaultListID, listName: defaultListName)
    ];
    activeListsAsArray.addAll((await FirestoreDB.getAllActiveLists(userID))!);
    for (var taskList in activeListsAsArray) {
      activeLists[taskList.listID] = taskList;
      allTaskListData[taskList.listID] = TaskListData();
    }
    activeTasks.sort(Task.deadlineComparator);
    for (var task in activeTasks) {
      var listId = task.taskListID;
      allTaskListData[listId]!.insertTaskInitialization(task);
      allListsCombined.insertTaskInitialization(task);
    }
    activeRepeatingTasks =
        (await FirestoreDB.getAllActiveRepeatingTasks(userID))!;

    isDataLoaded = true;
    notifyListeners();
  }

  Future<void> addRepeatingTask(Task task, RepeatCycle repeatCycle,
      RepeatFrequency? repeatFrequency) async {
    RepeatingTask repeatingTask = RepeatingTask(
      repeatingTaskId: task.taskID,
      repeatingTaskName: task.taskName,
      repeatCycle: repeatCycle,
      deadlineDate: task.deadlineDate!,
      repeatFrequency: repeatFrequency,
      deadlineTime: task.deadlineTime,
      taskListID: task.taskListID,
      isActive: true,
      currentTaskDeadlineDate: task.deadlineDate!,
      currentActiveTaskID: "dummy",
    );
    Task generatedTask = repeatingTask.generateFirstTask();
    var success = await FirestoreDB.insertRepeatingTask(
        repeatingTask, generatedTask, userID);
    if (!success) {
      print("could not insert into database");
    } else {
      _insertTaskIntoDS(generatedTask);
      activeRepeatingTasks[repeatingTask.repeatingTaskId] = repeatingTask;
    }
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    var taskAsMap = task.toFirestoreMap(userID);
    String? id = await FirestoreDB.insertTask(taskAsMap);
    if (id == null) {
      print("could not insert into database");
    } else {
      task.taskID = id;
      _insertTaskIntoDS(task);
    }

    notifyListeners();
  }

  void updateTask(Task task) async {
    bool success = await FirestoreDB.updateTask(task, userID);
    if (success == false) {
      print("could not update the task");
    }
    {
      _deleteModifiedTaskFromDS(task);
      _insertTaskIntoDS(task);
    }
    notifyListeners();
  }

  void deleteTask(Task task) async {
    //task variable may have been modified before deleting
    bool success = await FirestoreDB.deleteTask(task);
    if (success == false) {
      print("Could not delete task");
    } else {
      _deleteModifiedTaskFromDS(task);
      notifyListeners();
    }
  }

  void finishTask(Task task) async {
    if (task.isRepeating == false)
      _finishNonRepeatingTask(task);
    else
      _finishRepeatingTask(task);
  }

  void addList(String listName) async {
    TaskList taskList =
        TaskList(isActive: true, listID: "-1", listName: listName);
    var taskListAsMap = taskList.toFirestoreMap(userID);
    String? id = await FirestoreDB.insertList(taskListAsMap);
    if (id == null) {
      print("could not insert list into database");
    } else {
      taskList.listID = id;
      activeLists[id] = taskList;
      allTaskListData[id] = TaskListData();
      notifyListeners();
    }
  }

  List<Task> getSection(
      {required Section section, required String selectedListID}) {
    TaskListData selectedAggregatedTasks;
    if (selectedListID == allListName)
      selectedAggregatedTasks = allListsCombined;
    else if (selectedListID == selectedListID)
      selectedAggregatedTasks = allTaskListData[selectedListID]!;
    else {
      print("no such list. Wrong input parameter");
      return [];
    }
    return selectedAggregatedTasks.findListFromSection(section);
  }

  void _finishNonRepeatingTask(Task task) async {
    task.isFinished = true;
    bool success = await FirestoreDB.updateTask(task, userID);
    if (success) {
      _deleteTaskFromActiveDS(task);
      notifyListeners();
    } else
      task.isFinished = false;
  }

  void _finishRepeatingTask(Task task) async {
    RepeatingTask parentTask = activeRepeatingTasks[task.parentTaskID]!;
    Task nextTask = parentTask.generateNextTask();
    bool success = await FirestoreDB.finishRepeatingTask(
        task, nextTask, parentTask, userID);
    if (success) {
      _deleteTaskFromActiveDS(task);
      _insertTaskIntoDS(nextTask);
      notifyListeners();
    } else {
      print("error in finishing task");
    }
  }

  ///for inserting an active task into the in-memory Data Structures
  void _insertTaskIntoDS(Task task) {
    activeTasks.add(task);
    allTaskListData[task.taskListID]!.insertTask(task);
    allListsCombined.insertTask(task);
  }

  ///Used when you want to remove a task from DS with the same taskID as in the argument
  void _deleteModifiedTaskFromDS(Task task) {
    var index = _findTaskIndexInActiveTaskList(task);
    assert(index != null, "task not found in active task list");
    Task originalTask = activeTasks[index!];
    _deleteTaskFromActiveDS(originalTask);
  }

  ///deletes a task from in-memory data structures for pending tasks.
  ///example usage: when a task is finished or deleted
  void _deleteTaskFromActiveDS(Task task) {
    var index = _findTaskIndexInActiveTaskList(task);
    activeTasks.removeAt(index!);
    allTaskListData[task.taskListID]!.deleteOriginalTask(task);
    allListsCombined.deleteOriginalTask(task);
  }

  void _flushData() {
    isDataLoaded = false;
    activeTasks.clear();
    activeLists.clear();
    allTaskListData.clear();
    allListsCombined = TaskListData();
    activeRepeatingTasks = {};
  }

  int? _findTaskIndexInActiveTaskList(Task task) {
    var index = activeTasks.indexWhere((Task t) {
      return t.taskID == task.taskID;
    });

    if (index == -1) return null;
    return index;
  }
}
