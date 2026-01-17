import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../services/storage_service.dart';
import '../widgets/todo_item.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;

  const HomeScreen({Key? key, required this.storageService}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Todo> _todos = [];
  bool _isLoading = true;
  String _filter = 'All'; // All, Active, Done

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final todos = await widget.storageService.loadTodos();
    setState(() {
      _todos = todos;
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    await widget.storageService.saveTodos(_todos);
  }

  void _addTodo(String title, String description, TodoPriority priority) {
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      priority: priority,
      createdAt: DateTime.now(),
    );
    setState(() {
      _todos.add(newTodo);
      // Sort: High priority first, then new ones
      _sortTodos();
    });
    _saveData();
  }

  void _editTodo(Todo todo, String title, String description, TodoPriority priority) {
    setState(() {
      final index = _todos.indexWhere((element) => element.id == todo.id);
      if (index != -1) {
        _todos[index] = todo.copyWith(
          title: title,
          description: description,
          priority: priority,
        );
        _sortTodos();
      }
    });
    _saveData();
  }

  void _toggleTodo(String id, bool? value) {
    setState(() {
      final index = _todos.indexWhere((element) => element.id == id);
      if (index != -1) {
        _todos[index] = _todos[index].copyWith(isCompleted: value);
      }
    });
    _saveData();
  }

  void _deleteTodo(String id) {
    setState(() {
      _todos.removeWhere((element) => element.id == id);
    });
    _saveData();
  }

  void _sortTodos() {
    _todos.sort((a, b) {
      if (a.isCompleted == b.isCompleted) {
        if (a.priority != b.priority) {
          return b.priority.index.compareTo(a.priority.index); // High to Low
        }
        return b.createdAt.compareTo(a.createdAt); // New to Old
      }
      return a.isCompleted ? 1 : -1; // Active first
    });
  }

  List<Todo> get _filteredTodos {
    switch (_filter) {
      case 'Active':
        return _todos.where((t) => !t.isCompleted).toList();
      case 'Done':
        return _todos.where((t) => t.isCompleted).toList();
      default:
        return _todos;
    }
  }

  void _showAddEditDialog([Todo? todo]) {
    final titleController = TextEditingController(text: todo?.title ?? '');
    final descController = TextEditingController(text: todo?.description ?? '');
    TodoPriority priority = todo?.priority ?? TodoPriority.normal;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(todo == null ? 'New Task' : 'Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TodoPriority>(
                      value: priority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: TodoPriority.values.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(p.toString().split('.').last.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => priority = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      if (todo == null) {
                        _addTodo(titleController.text, descController.text, priority);
                      } else {
                        _editTodo(todo, titleController.text, descController.text, priority);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(todo == null ? 'ADD' : 'SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color handled by main theme
      appBar: AppBar(
        // Theme handles background and elevation
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'M',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: -1.0, // Tighter tracking for a logo feel
            ),
          ),
        ),
        actions: [
          // Removed redundant filter popup
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks yet',
                        style: TextStyle(color: Colors.grey[500], fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _filteredTodos.length,
                  itemBuilder: (context, index) {
                    final todo = _filteredTodos[index];
                    return TodoItem(
                      todo: todo,
                      onChanged: (val) => _toggleTodo(todo.id, val),
                      onDelete: () => _deleteTodo(todo.id),
                      onEdit: () => _showAddEditDialog(todo),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
        // Theme handles colors
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: ['All', 'Active', 'Done'].indexOf(_filter),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[400],
        showSelectedLabels: true,
        showUnselectedLabels: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        onTap: (index) {
          setState(() {
            _filter = ['All', 'Active', 'Done'][index];
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'All'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Active'),
          BottomNavigationBarItem(icon: Icon(Icons.done_all), label: 'Done'),
        ],
      ),
    );
  }
}