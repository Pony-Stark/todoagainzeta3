import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

//used to display in UI
const String noRepeat = "No Repeat";
const String defaultListName = "Default";
const String defaultListID = "1";
const String allListName = 'All Lists';

enum RepeatCycle {
  onceADay,
  onceADayMonFri,
  onceAWeek,
  onceAMonth,
  onceAYear,
  other,
}

String repeatCycleToUIString(RepeatCycle r) {
  Map<RepeatCycle, String> mapper = {
    RepeatCycle.onceADay: "Once A Day",
    RepeatCycle.onceADayMonFri: "Once A Day( Mon-Fri )",
    RepeatCycle.onceAWeek: "Once A Week",
    RepeatCycle.onceAMonth: "Once A Month",
    RepeatCycle.onceAYear: "Once A Year",
    RepeatCycle.other: "Other...",
  };
  return (mapper[r]!);
}

enum Tenure { days, weeks, months, years }

class RepeatFrequency {
  RepeatFrequency({required this.num, required this.tenure});
  int num;
  Tenure tenure;
}

class Task {
  Task({
    required this.taskName,
    required this.taskListID,
    required this.taskID,
    required this.isFinished,
    required this.isRepeating,
    this.parentTaskID,
    this.deadlineDate,
    this.deadlineTime,
  });

  Task.fromTask(task)
      : this.taskName = task.taskName,
        this.taskListID = task.taskListID,
        this.taskID = task.taskID,
        this.isFinished = task.isFinished,
        this.isRepeating = task.isRepeating,
        this.parentTaskID = task.parentTaskID,
        this.deadlineDate = task.deadlineDate,
        this.deadlineTime = task.deadlineTime;
  String taskID;
  String taskListID;
  String? parentTaskID; //used for repeated task instances only
  String taskName;
  DateTime? deadlineDate;
  TimeOfDay? deadlineTime;
  bool isFinished;
  bool isRepeating;

  // Map<String, dynamic> toMap() {
  //   Map<String, dynamic> taskAsMap = {
  //     "taskID": int.parse(taskID),
  //     "taskListID": int.parse(taskListID),
  //     "parentTaskID": null,
  //     "taskName": taskName,
  //     "deadlineDate":
  //         deadlineDate == null ? null : deadlineDate!.millisecondsSinceEpoch,
  //     "deadlineTime":
  //         deadlineTime == null ? null : intFromTimeOfDay(deadlineTime!),
  //     "isFinished": isFinished == true ? 1 : 0,
  //     "isRepeating": isRepeating == true ? 1 : 0,
  //   };
  //   return (taskAsMap);
  // }

  // static Task fromMap(Map<String, dynamic> taskAsMap) {
  //   Task task = Task(
  //     taskID: taskAsMap["taskID"].toString(),
  //     taskListID: taskAsMap["taskListID"].toString(),
  //     parentTaskID: taskAsMap["parentTaskID"],
  //     taskName: taskAsMap["taskName"],
  //     deadlineDate: taskAsMap["deadlineDate"] == null
  //         ? null
  //         : DateTime.fromMillisecondsSinceEpoch(taskAsMap["deadlineDate"]),
  //     deadlineTime: taskAsMap["deadlineTime"] == null
  //         ? null
  //         : timeOfDayFromInt(taskAsMap["deadlineTime"]),
  //     isFinished: taskAsMap["isFinished"] == 0 ? false : true,
  //     isRepeating: taskAsMap["isRepeating"] == 0 ? false : true,
  //   );
  //   return (task);
  // }

  static Task fromFirestoreMap(Map<String, dynamic> taskAsMap, String taskID) {
    Task task = Task(
      taskID: taskID,
      taskListID: taskAsMap["taskListID"],
      parentTaskID: taskAsMap["parentTaskID"],
      taskName: taskAsMap["taskName"],
      deadlineDate: taskAsMap["deadlineDate"] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(taskAsMap["deadlineDate"]),
      deadlineTime: taskAsMap["deadlineTime"] == null
          ? null
          : timeOfDayFromInt(taskAsMap["deadlineTime"]),
      isFinished: taskAsMap["isFinished"] == 0 ? false : true,
      isRepeating: taskAsMap["isRepeating"] == 0 ? false : true,
    );
    return (task);
  }

  Map<String, dynamic> toFirestoreMap(String uid) {
    Map<String, dynamic> taskAsMap = {
      "uid": uid,
      "taskListID": taskListID,
      "parentTaskID": parentTaskID,
      "taskName": taskName,
      "deadlineDate":
          deadlineDate == null ? null : deadlineDate!.millisecondsSinceEpoch,
      "deadlineTime":
          deadlineTime == null ? null : intFromTimeOfDay(deadlineTime!),
      "isFinished": isFinished == true ? 1 : 0,
      "isRepeating": isRepeating == true ? 1 : 0,
    };
    return (taskAsMap);
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
}

int intFromTimeOfDay(TimeOfDay tod) {
  return (tod.minute + 60 * tod.hour);
}

TimeOfDay timeOfDayFromInt(int todInt) {
  return TimeOfDay(hour: todInt ~/ 60, minute: todInt % 60);
}

class RepeatingTask {
  RepeatingTask({
    required this.repeatingTaskId,
    required this.repeatingTaskName,
    required this.repeatCycle,
    required this.deadlineDate,
    this.repeatFrequency,
    this.deadlineTime,
    required this.taskListID,
    required this.isActive,
    required this.currentTaskDeadlineDate, //used to generate new task.
    required this.currentActiveTaskID,
  });
  String taskListID;
  String repeatingTaskId;
  String repeatingTaskName;
  RepeatCycle repeatCycle;
  RepeatFrequency? repeatFrequency;
  DateTime deadlineDate;
  TimeOfDay? deadlineTime;
  bool isActive;
  DateTime currentTaskDeadlineDate;
  String currentActiveTaskID;

  Map<String, dynamic> toFirestoreMap(String uid) {
    return {
      "uid": uid,
      "taskListID": taskListID,
      "repeatingTaskName": repeatingTaskName,
      "repeatCycle": describeEnum(repeatCycle),
      "repeatFrequencyNum":
          repeatFrequency == null ? null : repeatFrequency!.num,
      "repeatFrequencyTenure": repeatFrequency == null
          ? null
          : describeEnum(repeatFrequency!.tenure),
      "deadlineDate": deadlineDate.millisecondsSinceEpoch,
      "deadlineTime":
          deadlineTime == null ? null : intFromTimeOfDay(deadlineTime!),
      "isActive": isActive == true ? 1 : 0,
      "currentTaskDeadlineDate": currentTaskDeadlineDate.millisecondsSinceEpoch,
      "currentActiveTaskID": currentActiveTaskID,
    };
  }

  static RepeatingTask fromFirestoreMap(
      Map<String, dynamic> repeatingTaskAsMap, String repeatingTaskId) {
    RepeatCycle repeatCycle = RepeatCycle.values.firstWhere(
        (e) => describeEnum(e) == repeatingTaskAsMap["repeatCycle"]);
    RepeatFrequency? repeatFrequency = null;

    if (repeatCycle == RepeatCycle.other) {
      repeatFrequency = RepeatFrequency(
          num: repeatingTaskAsMap["repeatFrequencyNum"],
          tenure: Tenure.values.firstWhere((e) =>
              describeEnum(e) == repeatingTaskAsMap["repeatFrequencyTenure"]));
    }

    return RepeatingTask(
        taskListID: repeatingTaskAsMap["taskListID"],
        repeatingTaskName: repeatingTaskAsMap["repeatingTaskName"],
        repeatingTaskId: repeatingTaskId,
        repeatCycle: repeatCycle,
        deadlineDate: DateTime.fromMillisecondsSinceEpoch(
            repeatingTaskAsMap["deadlineDate"]),
        deadlineTime: repeatingTaskAsMap["deadlineTime"] == null
            ? null
            : timeOfDayFromInt(repeatingTaskAsMap["deadlineTime"]),
        repeatFrequency: repeatFrequency,
        isActive: repeatingTaskAsMap["isActive"] == 1 ? true : false,
        currentTaskDeadlineDate: DateTime.fromMillisecondsSinceEpoch(
            repeatingTaskAsMap["currentTaskDeadlineDate"]),
        currentActiveTaskID: repeatingTaskAsMap["currentActiveTaskID"]);
  }

  DateTime findNextTaskDeadline() {
    RepeatFrequency effectiveRepeatFrequency;
    if (repeatCycle == RepeatCycle.other)
      effectiveRepeatFrequency = repeatFrequency!;
    else if (repeatCycle == RepeatCycle.onceADay)
      effectiveRepeatFrequency = RepeatFrequency(num: 1, tenure: Tenure.days);
    else if (repeatCycle == RepeatCycle.onceAWeek)
      effectiveRepeatFrequency = RepeatFrequency(num: 1, tenure: Tenure.weeks);
    else if (repeatCycle == RepeatCycle.onceAMonth)
      effectiveRepeatFrequency = RepeatFrequency(num: 1, tenure: Tenure.months);
    else if (repeatCycle == RepeatCycle.onceAYear)
      effectiveRepeatFrequency = RepeatFrequency(num: 1, tenure: Tenure.years);
    else {
      assert(repeatCycle == RepeatCycle.onceADayMonFri);
      if (currentTaskDeadlineDate.weekday == DateTime.friday)
        return currentTaskDeadlineDate.add(Duration(days: 3));
      else
        return currentTaskDeadlineDate.add(Duration(days: 1));
    }
    if (effectiveRepeatFrequency.tenure == Tenure.days)
      return currentTaskDeadlineDate
          .add(Duration(days: effectiveRepeatFrequency.num));
    if (effectiveRepeatFrequency.tenure == Tenure.weeks)
      return currentTaskDeadlineDate
          .add(Duration(days: 7 * (effectiveRepeatFrequency.num)));
    DateTime nextDeadline;
    if (effectiveRepeatFrequency.tenure == Tenure.months) {
      nextDeadline = DateTime(
          currentTaskDeadlineDate.year,
          currentTaskDeadlineDate.month + effectiveRepeatFrequency.num,
          currentTaskDeadlineDate.day);
      if (nextDeadline.month - currentTaskDeadlineDate.month !=
          effectiveRepeatFrequency.num)
        nextDeadline = DateTime(nextDeadline.year, nextDeadline.month, 0);
      return nextDeadline;
    }
    if (effectiveRepeatFrequency.tenure == Tenure.years) {
      nextDeadline = DateTime(
          currentTaskDeadlineDate.year + effectiveRepeatFrequency.num,
          currentTaskDeadlineDate.month,
          currentTaskDeadlineDate.day);
      if (nextDeadline.month != currentTaskDeadlineDate.month)
        nextDeadline = DateTime(nextDeadline.year, nextDeadline.month, 0);
      return nextDeadline;
    }
    assert(0 == 1, "We should not reach here");
    return DateTime.now();
  }

  Task generateNextTask() {
    Task task = generateFirstTask();
    task.parentTaskID = repeatingTaskId;
    task.deadlineDate = findNextTaskDeadline();
    return task;
  }

  Task generateFirstTask() {
    return Task(
      taskName: repeatingTaskName,
      taskListID: taskListID,
      taskID: "dummy",
      isFinished: false,
      isRepeating: true,
      parentTaskID: repeatingTaskId,
      deadlineDate: deadlineDate,
      deadlineTime: deadlineTime,
    );
  }
}

class TaskList {
  String listID;
  String listName;
  bool isActive;
  /*List<Task> nonRepeatingTasks;
  List<RepeatingTask> repeatingTasks;
  List<Task> activeRepeatingTaskInstances;*/
  TaskList({
    required this.isActive,
    required this.listID,
    required this.listName,
  });

  Map<String, dynamic> toMap() {
    return {
      "listID": int.parse(listID),
      "listName": listName,
      "isActive": isActive == true ? 1 : 0
    };
  }

  static TaskList fromMap(Map<String, dynamic> taskListAsMap) {
    return (TaskList(
      isActive: taskListAsMap["isActive"] == 1 ? true : false,
      listID: taskListAsMap["listID"].toString(),
      listName: taskListAsMap["listName"],
    ));
  }

  Map<String, dynamic> toFirestoreMap(String uid) {
    return {
      "uid": uid,
      "listName": listName,
      "isActive": isActive == true ? 1 : 0
    };
  }

  static TaskList fromFirestoreMap(
      Map<String, dynamic> taskListAsMap, String listID) {
    return (TaskList(
      isActive: taskListAsMap["isActive"] == 1 ? true : false,
      listID: listID,
      listName: taskListAsMap["listName"],
    ));
  }
}
