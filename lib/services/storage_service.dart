import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

abstract class StorageService {
  Future<List<Todo>> loadTodos();
  Future<void> saveTodos(List<Todo> todos);
}

class LocalStorageService implements StorageService {
  static const String _keyTodos = 'todoList_v2';

  @override
  Future<List<Todo>> loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todosString = prefs.getString(_keyTodos);
    if (todosString == null) return [];

    try {
      final List<dynamic> decodedList = json.decode(todosString);
      return decodedList.map((item) => Todo.fromMap(item)).toList();
    } catch (e) {
      print('Error loading todos: $e');
      return [];
    }
  }

  @override
  Future<void> saveTodos(List<Todo> todos) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = json.encode(todos.map((t) => t.toMap()).toList());
    await prefs.setString(_keyTodos, encodedList);
  }
}

class InMemoryStorageService implements StorageService {
  List<Todo> _todos = [];

  @override
  Future<List<Todo>> loadTodos() async {
    return List.from(_todos);
  }

  @override
  Future<void> saveTodos(List<Todo> todos) async {
    _todos = List.from(todos);
  }
}