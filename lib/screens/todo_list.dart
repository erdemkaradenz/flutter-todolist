import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_todolist/screens/add_page.dart';
import 'package:http/http.dart' as http;

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  bool isLoading = true;
  List items = [];
  List completedItems = [];
  List pendingItems = [];

  @override
  void initState() {
    super.initState();
    fetchTodo();
  }

  Future<void> fetchTodo() async {
    final url = 'http://api.nstack.in/v1/todos?page=1&limit=10';
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      final result = json['items'] as List;

      final completed = result.where((item) => item['is_completed'] == true).toList();
      final pending = result.where((item) => item['is_completed'] == false).toList();

      setState(() {
        items = result;
        completedItems = completed;
        pendingItems = pending;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      // Handle error case here
    }
  }

  Future<void> updateTodoStatus(Map item, bool isCompleted) async {
    final id = item['_id'];
    final url = 'http://api.nstack.in/v1/todos/$id';
    final uri = Uri.parse(url);

    // Add all necessary fields to the body
    final body = jsonEncode({
      'title': item['title'],
      'description': item['description'],
      'is_completed': isCompleted
    });

    final headers = {'Content-Type': 'application/json'};

    print('Updating todo status for id: $id');
    print('Request body: $body');
    print('Request headers: $headers');

    try {
      final response = await http.put(
        uri,
        body: body,
        headers: headers,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        fetchTodo();
      } else {
        print('Failed to update the item. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Exception during update: $e');
      // Handle exception as per your requirement
    }
  }

  void navigateToAddPage() async {
    final route = MaterialPageRoute(
      builder: (context) => AddTodoPage(),
    );
    await Navigator.push(context, route);
    fetchTodo();
  }

  void navigateToEditPage(Map item) async {
    final route = MaterialPageRoute(
      builder: (context) => AddTodoPage(todo: item),
    );
    await Navigator.push(context, route);
    fetchTodo();
  }

  Future<void> deleteById(String id) async {
    final url = 'http://api.nstack.in/v1/todos/$id';
    final uri = Uri.parse(url);
    final response = await http.delete(uri);
    if (response.statusCode == 200) {
      fetchTodo();
    } else {
      print('Failed to delete the item. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Todo List'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Bekleyen Görevler'),
              Tab(text: 'Tamamlanan Görevler'),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            buildTaskList(pendingItems),
            buildTaskList(completedItems),
          ],
        ),
      ),
    );
  }

  Widget buildTaskList(List tasks) {
    return RefreshIndicator(
      onRefresh: fetchTodo,
      child: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final item = tasks[index];
          final id = item['_id'];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(item['title'] ?? 'No Title'),
              subtitle: Text(item['description'] ?? 'No Description'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: item['is_completed'],
                    onChanged: (bool? value) {
                      if (value != null) {
                        updateTodoStatus(item, value);
                      }
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      if (value == 'edit') {
                        navigateToEditPage(item);
                      } else if (value == 'delete') {
                        deleteById(id);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
