import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

void main() => runApp(PulseApp());

class PulseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PULSE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A2E),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: PulseHome(),
    );
  }
}

class PulseHome extends StatefulWidget {
  @override
  _PulseHomeState createState() => _PulseHomeState();
}

class _PulseHomeState extends State<PulseHome> {
  List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _controller = TextEditingController();
  String _activeCategory = 'NURSING';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('pulse_tasks');
    if (tasksJson != null) {
      setState(() => _tasks = List<Map<String, dynamic>>.from(json.decode(tasksJson)));
    }
  }

  _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('pulse_tasks', json.encode(_tasks));
  }

  void _addTask() {
    if (_controller.text.isEmpty) return;
    setState(() {
      _tasks.add({
        'title': _controller.text,
        'category': _activeCategory,
        'isDone': false,
        'timestamp': DateTime.now().toString(),
      });
      _controller.clear();
    });
    _saveTasks();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    double progress = _tasks.isEmpty 
        ? 0 
        : _tasks.where((t) => t['isDone']).length / _tasks.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text("PULSE", style: GoogleFonts.exo2(fontWeight: FontWeight.w800, color: Colors.black87)),
              background: Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircularProgressIndicator(value: progress, strokeWidth: 8, backgroundColor: Colors.grey[200]),
                      const SizedBox(height: 10),
                      Text("${(progress * 100).toInt()}% DAILY GOAL", style: GoogleFonts.inter(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['NURSING', 'DEV'].map((cat) => ChoiceChip(
                  label: Text(cat),
                  selected: _activeCategory == cat,
                  onSelected: (val) => setState(() => _activeCategory = cat),
                )).toList(),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final task = _tasks[index];
                if (task['category'] != _activeCategory) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[100]!)),
                    child: ListTile(
                      leading: Checkbox(
                        value: task['isDone'],
                        onChanged: (val) {
                          setState(() => task['isDone'] = val);
                          _saveTasks();
                        },
                      ),
                      title: Text(task['title'], style: TextStyle(decoration: task['isDone'] ? TextDecoration.lineThrough : null)),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () {
                        setState(() => _tasks.removeAt(index));
                        _saveTasks();
                      }),
                    ),
                  ),
                );
              },
              childCount: _tasks.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text("NEW TASK"),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _controller, autofocus: true, decoration: const InputDecoration(hintText: "What needs to be done?", border: InputBorder.none)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _addTask, child: const Text("ADD TO PULSE")),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
