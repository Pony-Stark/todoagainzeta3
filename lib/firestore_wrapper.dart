import "package:cloud_firestore/cloud_firestore.dart";
import "task.dart";

class FirestoreDB {
  static FirebaseFirestore instance = FirebaseFirestore.instance;

  static Future<String?> createTask(Map<String, dynamic> taskAsMap) async {
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
      var addedData =
          await instance.collection("Task").where('uid', isEqualTo: uid).get();
      List<Task> result = [];
      for (var doc in addedData.docs) {
        result.add(Task.fromFirestoreMap(doc.data(), doc.id));
      }
      return result;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<String?> updateTask(Task task) async {
    try {
      var addedData =
      await instance.collection("Task").doc(task.taskID).update(task.toMap());
    } catch (e) {
      print(e);
      return null;
    }
  }
}
