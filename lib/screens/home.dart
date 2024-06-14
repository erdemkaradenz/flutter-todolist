import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_todolist/screens/add_page.dart';
import 'package:flutter_todolist/screens/todo_list.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = true;
  int totalTasks = 0;
  int completedTasks = 0;
  int pendingTasks = 0;
  List<Map<String, dynamic>> pendingTaskList = [];

  @override
  void initState() {
    super.initState();
    fetchSummary();
  }

  Future<void> fetchSummary() async {
    final url = 'http://api.nstack.in/v1/todos';
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      final items = json['items'] as List;

      int completed = items.where((item) => item['is_completed'] == true).length;
      int pending = items.where((item) => item['is_completed'] == false).length;
      List<Map<String, dynamic>> pendingTasksList = items.where((item) => item['is_completed'] == false).map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();

      setState(() {
        totalTasks = items.length;
        completedTasks = completed;
        pendingTasks = pending;
        pendingTaskList = pendingTasksList.take(3).toList();
        isLoading = false;
      });
    } else {
      // Handle error case here
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: fetchSummary,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            Card(
              child: ListTile(
                title: Text('Toplam Görev'),
                trailing: Text(totalTasks.toString()),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Tamamlanan Görev'),
                trailing: Text(completedTasks.toString()),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Bekleyen Görev'),
                trailing: Text(pendingTasks.toString()),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Bekleyen Görevler',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: pendingTaskList.length,
              itemBuilder: (context, index) {
                final item = pendingTaskList[index];
                return Card(
                  child: ListTile(
                    title: Text(item['title'] ?? 'No Title'),
                    subtitle: Text(item['description'] ?? 'No Description'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TodoListPage()),
          );
        },
        child: Icon(Icons.list),
      ),
    );
  }
}
