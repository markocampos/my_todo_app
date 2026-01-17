import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(TodoApp());

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<String> _todoItems = [];
  final TextEditingController _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load data from phone storage
  _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _todoItems = prefs.getStringList('todoList') ?? [];
    });
  }

  // Save data to phone storage
  _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('todoList', _todoItems);
  }

  void _addTodoItem(String task) {
    if (task.isNotEmpty) {
      setState(() {
        _todoItems.add(task);
      });
      _saveData();
      _textFieldController.clear();
    }
  }

  void _removeTodoItem(int index) {
    setState(() {
      _todoItems.removeAt(index);
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nursing & Code Tasks')),
      body: ListView.builder(
        itemCount: _todoItems.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: Key(_todoItems[index] + index.toString()),
            onDismissed: (direction) => _removeTodoItem(index),
            background: Container(color: Colors.red, child: Icon(Icons.delete, color: Colors.white)),
            child: ListTile(title: Text(_todoItems[index])),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _displayDialog(),
        child: Icon(Icons.add),
      ),
    );
  }

  _displayDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add a new task'),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(hintText: "Enter task here"),
          ),
          actions: [
            TextButton(child: Text('ADD'), onPressed: () {
              _addTodoItem(_textFieldController.text);
              Navigator.of(context).pop();
            })
          ],
        );
      },
    );
  }
}
