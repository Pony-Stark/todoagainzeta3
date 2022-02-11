import "package:cloud_firestore/cloud_firestore.dart";
import 'task.dart';

class FirestoreDB {
  static FirebaseFirestore instance = FirebaseFirestore.instance;
  static Future<String?> insertTask(Map<String, dynamic> taskAsMap) async {
    try {
      var addedData = await instance.collection("Task").add(taskAsMap);
      return addedData.id;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<List<Task>?> getAllPendingTasks(String uid) async {
    try {
      var readData = await instance
          .collection("Task")
          .where("uid", isEqualTo: uid)
          .where("isFinished", isEqualTo: 0)
          .get();
      List<Task> result = [];
      for (var doc in readData.docs) {
        result.add(Task.fromFirestoreMap(doc.data(), doc.id));
      }
      return result;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<bool> updateTask(Task task, String uid) async {
    try {
      await instance
          .collection("Task")
          .doc(task.taskID)
          .set(task.toFirestoreMap(uid));
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static Future<bool> deleteTask(Task task) async {
    try {
      await instance.collection("Task").doc(task.taskID).delete();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static Future<String?> insertList(Map<String, dynamic> taskListData) async {
    try {
      var addedList = await instance.collection("List").add(taskListData);
      return addedList.id;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<List<TaskList>?> getAllActiveLists(String uid) async {
    try {
      var readData = await instance
          .collection("List")
          .where("uid", isEqualTo: uid)
          .where("isActive", isEqualTo: 1)
          .get();
      List<TaskList> result = [];
      for (var doc in readData.docs) {
        result.add(TaskList.fromFirestoreMap(doc.data(), doc.id));
      }
      return result;
    } catch (e) {
      print(e);
      return null;
    }
  }

  ///inserts repeating task into db along with its first generated task.
  ///Side effect: modifies the id's and foreign keys of objects repeatingTask and generatedTask
  ///that are passed by reference
  static Future<bool> insertRepeatingTask(
      RepeatingTask repeatingTask, Task generatedTask, String userID) async {
    try {
      var repeatingTaskDoc = instance.collection('RepeatingTask').doc();
      generatedTask.parentTaskID = repeatingTaskDoc.id;
      repeatingTask.repeatingTaskId = repeatingTaskDoc.id;

      var taskDoc = instance.collection('Task').doc();
      repeatingTask.currentActiveTaskID = taskDoc.id;
      generatedTask.taskID = taskDoc.id;

      Map<String, dynamic> repeatingTaskAsMap =
          repeatingTask.toFirestoreMap(userID);
      Map<String, dynamic> generatedTaskAsMap =
          generatedTask.toFirestoreMap(userID);
      await instance.runTransaction((transaction) async {
        transaction.set(repeatingTaskDoc, repeatingTaskAsMap);
        transaction.set(taskDoc, generatedTaskAsMap);
      });
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static Future<Map<String, RepeatingTask>?> getAllActiveRepeatingTasks(
      String uid) async {
    try {
      var readData = await instance
          .collection("RepeatingTask")
          .where("uid", isEqualTo: uid)
          .where("isActive", isEqualTo: 1)
          .get();
      Map<String, RepeatingTask> result = {};
      for (var doc in readData.docs) {
        result[doc.id] = RepeatingTask.fromFirestoreMap(doc.data(), doc.id);
      }
      return result;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<bool> finishRepeatingTask(Task currentTask, Task nextTask,
      RepeatingTask repeatingTask, String uid) async {
    try {
      var nextTaskDoc = instance.collection('Task').doc();
      nextTask.taskID = nextTaskDoc.id;
      var nextTaskAsMap = nextTask.toFirestoreMap(uid);

      await instance.runTransaction((transaction) async {
        transaction.update(
          instance
              .collection('RepeatingTask')
              .doc(repeatingTask.repeatingTaskId),
          {
            "currentTaskDeadlineDate":
                nextTask.deadlineDate!.millisecondsSinceEpoch,
            "currentActiveTaskID": nextTaskDoc.id
          },
        );
        transaction.update(instance.collection('Task').doc(currentTask.taskID),
            {"isFinished": 1});
        transaction.set(nextTaskDoc, nextTaskAsMap);
      });
      currentTask.isFinished = true;
      repeatingTask.currentTaskDeadlineDate = nextTask.deadlineDate!;
      repeatingTask.currentActiveTaskID = nextTaskDoc.id;
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
