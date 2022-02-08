import "package:path/path.dart";
import 'package:sqflite/sqflite.dart';
import 'task.dart';

class SqliteDB {
  SqliteDB.internal();
  static Database? _db;
  static Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await initDb();
    return _db!;
  }

  static Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future _onCreate(Database db, int t) async {
    await db.execute('CREATE TABLE LIST (listID INTEGER PRIMARY KEY, '
        'listName TEXT, '
        'isActive INTEGER)');

    await db.execute('CREATE TABLE TASK (taskID INTEGER PRIMARY KEY, '
        'taskListID INTEGER, '
        'parentTaskID INTEGER, '
        'taskName TEXT, '
        'deadlineDate INTEGER, '
        'deadlineTime INTEGER, '
        'isFinished INTEGER, '
        'isRepeating INTEGER, '
        'FOREIGN KEY (taskListId) REFERENCES LIST (listID) ON DELETE NO ACTION ON UPDATE NO ACTION)');
    await db.insert("LIST", {
      "listID": defaultListID,
      "listName": defaultListName,
      "isActive": 1,
    });
  }

  /// Initialize DB
  static initDb() async {
    String folderPath = await getDatabasesPath();
    String path = join(folderPath, "todo.db");
    await deleteDatabase(path);

    var taskDb = await openDatabase(
      path,
      version: 3,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
    _db = taskDb;
    return taskDb;
  }

  /// Count number of tables in DB
  static Future<int?> insertTask(Map<String, dynamic> taskData) async {
    var dbClient = await db;
    int id = await dbClient.insert("TASK", taskData);
    if (id != 0) {
      return (id);
    } else {
      return (null);
    }
  }

  ///returns all taks whose isFinished is false
  static Future<List<Task>> getAllPendingTasks() async {
    var dbClient = await db;
    List<Map<String, dynamic>> tasksFromDB =
        await dbClient.query("TASK", where: "isFinished = ?", whereArgs: [0]);
    List<Task> tasksAsObjects = [];
    for (var map in tasksFromDB) {
      tasksAsObjects.add(Task.fromMap(map));
    }
    return (tasksAsObjects);
  }

  static Future<bool> updateTask(Task task) async {
    var dbClient = await db;
    int changes = await dbClient.update("TASK", task.toMap(),
        where: "taskID = ?", whereArgs: [task.taskID]);
    return (changes > 0);
  }

  static Future<bool> deleteTask(Task task) async {
    var dbClient = await db;
    int changes = await dbClient
        .delete("TASK", where: "taskID = ?", whereArgs: [task.taskID]);
    return (changes == 1);
  }

  static Future<List<TaskList>> getAllActiveLists() async {
    var dbClient = await db;
    List<Map<String, dynamic>> taskListsFromDB =
        await dbClient.query("LIST", where: "isActive = ?", whereArgs: [1]);
    List<TaskList> taskListAsObjects = [];
    for (var map in taskListsFromDB) {
      print(map);
      taskListAsObjects.add(TaskList.fromMap(map));
    }
    return (taskListAsObjects);
  }

  static Future<int?> insertList(Map<String, dynamic> taskListData) async {
    var dbClient = await db;
    int id = await dbClient.insert("LIST", taskListData);
    if (id != 0) {
      return (id);
    } else {
      return (null);
    }
  }
}
