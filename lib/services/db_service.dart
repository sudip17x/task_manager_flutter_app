import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class DBService {
  static const String boxName = 'tasksBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    await Hive.openBox<Task>(boxName);
  }

  static Box<Task> get _box => Hive.box<Task>(boxName);

  static List<Task> getAllTasks() {
    return _box.values.toList();
  }

  static Future<void> addTask(Task task) async {
    await _box.put(task.id, task);
  }

  static Future<void> updateTask(Task task) async {
    await _box.put(task.id, task);
  }

  static Future<void> deleteTask(String id) async {
    await _box.delete(id);
  }
}
