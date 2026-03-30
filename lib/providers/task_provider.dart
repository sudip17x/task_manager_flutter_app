import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/db_service.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedStatus = 'All'; // 'All', 'To-Do', 'In Progress', 'Done'
  Timer? _debounce;

  TaskProvider() {
    _loadTasks();
  }

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedStatus => _selectedStatus;

  List<Task> get filteredTasks {
    return _tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatus == 'All' || task.status == _selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _loadTasks() {
    _tasks = DBService.getAllTasks();
    notifyListeners();
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      notifyListeners();
    });
  }

  void setFilterStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 2)); // Simulate API delay
    await DBService.addTask(task);
    _tasks.add(task);
    _setLoading(false);
  }

  Future<void> updateTask(Task task) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 2)); // Simulate API delay
    await DBService.updateTask(task);
    int index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
    _setLoading(false);
  }

  Future<void> deleteTask(String id) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 2)); // Simulate API delay
    await DBService.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    // Also remove blockedBy references if any task is blocked by the deleted one
    for (var i = 0; i < _tasks.length; i++) {
      if (_tasks[i].blockedBy == id) {
        _tasks[i] = _tasks[i].copyWith(blockedBy: null);
        await DBService.updateTask(_tasks[i]);
      }
    }
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  bool isTaskBlocked(Task task) {
    if (task.blockedBy == null || task.blockedBy!.isEmpty) return false;
    try {
      final blockingTask = _tasks.firstWhere((t) => t.id == task.blockedBy);
      return blockingTask.status != 'Done';
    } catch (e) {
      return false; // Blocking task not found
    }
  }

  bool isTaskUsedAsDependency(String id) {
    return _tasks.any((task) => task.blockedBy == id);
  }
}
