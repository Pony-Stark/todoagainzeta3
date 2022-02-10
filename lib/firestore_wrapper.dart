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
}
