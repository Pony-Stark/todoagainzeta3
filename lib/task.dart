import 'package:flutter/material.dart';

//used to display in UI
const String noRepeat = "No Repeat";
const String defaultListName = "Default";
const int defaultListID = 1;

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

  String taskID;
  int taskListID;
  int? parentTaskID; //used for repeated task instances only
  String taskName;
  DateTime? deadlineDate;
  TimeOfDay? deadlineTime;
  bool isFinished;
  bool isRepeating;
  void finishTask() {
    isFinished = true;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> taskAsMap = {
      "taskID": taskID,
      "taskListID": taskListID,
      "parentTaskID": null,
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

  static Task fromMap(Map<String, dynamic> taskAsMap) {
    Task task = Task(
      //TODO::remove toString once we start reading from firestore
      taskID: taskAsMap["taskID"].toString(),
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

  static Task fromFirestoreMap(
      Map<String, dynamic> taskAsFirestoreMap, String taskID) {
    Task task = Task(
      taskID: taskID,
      taskListID: taskAsFirestoreMap["taskListID"],
      parentTaskID: taskAsFirestoreMap["parentTaskID"],
      taskName: taskAsFirestoreMap["taskName"],
      deadlineDate: taskAsFirestoreMap["deadlineDate"] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              taskAsFirestoreMap["deadlineDate"]),
      deadlineTime: taskAsFirestoreMap["deadlineTime"] == null
          ? null
          : timeOfDayFromInt(taskAsFirestoreMap["deadlineTime"]),
      isFinished: taskAsFirestoreMap["isFinished"] == 0 ? false : true,
      isRepeating: taskAsFirestoreMap["isRepeating"] == 0 ? false : true,
    );
    return (task);
  }

  Map<String, dynamic> toFirestoreMap(String uid) {
    Map<String, dynamic> taskAsMap = {
      "uid": uid,
      "taskListID": taskListID,
      "parentTaskID": null,
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
  });
  int taskListID;
  int repeatingTaskId;
  String repeatingTaskName;
  RepeatCycle repeatCycle;
  RepeatFrequency? repeatFrequency;
  DateTime deadlineDate;
  DateTime? deadlineTime;
}

class TaskList {
  int listID;
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
      "listID": listID,
      "listName": listName,
      "isActive": isActive == true ? 1 : 0
    };
  }

  static TaskList fromMap(Map<String, dynamic> taskListAsMap) {
    return (TaskList(
      isActive: taskListAsMap["isActive"] == 1 ? true : false,
      listID: taskListAsMap["listID"],
      listName: taskListAsMap["listName"],
    ));
  }

  /*List<Task> getActiveTasks() {
    //TODO::Select repeating Task Instances as well
    List<Task> activeNonRepeatingTasks = [];
    {
      for (var i = 0; i < nonRepeatingTasks.length; i++) {
        if (nonRepeatingTasks[i].finished == false) {
          activeNonRepeatingTasks.add(nonRepeatingTasks[i]);
        }
      }
      return (activeNonRepeatingTasks);
    }
  }*/

  /*List<Task> getFinishedTasks() {
    //repeating Instances as well as non-repeating Instances
    return ([]);
  }

  void FinishTask(Task task) {}*/

  /*void addTask({
    required String taskName,
    DateTime? deadlineDate,
    TimeOfDay? deadlineTime,
    int? parentTaskID,
  }) {
    //
    Task(
      taskName: taskName,
      finished: false,
      taskListID: taskListID,
      deadlineDate: deadlineDate,
      deadlineTime: deadlineTime,
      parentTaskID: parentTaskID,
    );

    if (parentTaskID != null) {
      //
    }
  }*/

  /*void finishTask(Task task) {}*/
}
