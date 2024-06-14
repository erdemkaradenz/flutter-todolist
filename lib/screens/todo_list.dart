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

  @override
  void initState() {
    super.initState();
    fetchTodo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
      ),
      body: Visibility(
        visible: isLoading,
        child: Center(
          child: CircularProgressIndicator(),
        ),
        replacement: RefreshIndicator(
          onRefresh: fetchTodo,
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index] as Map;
              final id = item['_id']?.toString() ?? ''; // Null check here
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(item['title'] ?? 'No Title'), // Null check here
                subtitle: Text(item['description'] ?? 'No Description'), // Null check here
                trailing: PopupMenuButton(
                  onSelected: (value) {
                    if (value == 'edit') {
                      // Open edit page
                      navigateToEditPage(item);
                    } else if (value == 'delete') {
                      // Delete and remove the item
                      print('Deleting item with id: $id');
                      deleteById(id);
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        child: Text('Edit'),
                        value: 'edit',
                      ),
                      PopupMenuItem(
                        child: Text('Delete'),
                        value: 'delete',
                      ),
                    ];
                  },
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: navigateToAddPage,
        label: Text('Add Todo'),
      ),
    );
  }

  Future<void> navigateToEditPage(Map item) async {
    final route = MaterialPageRoute(
      builder: (context) => AddTodoPage(todo:item),
    );
    await Navigator.push(context, route);
    setState(() {
      isLoading=true;
    });
    fetchTodo();
  }

  Future<void> navigateToAddPage() async {
    final route = MaterialPageRoute(
      builder: (context) => AddTodoPage(),
    );
    await Navigator.push(context, route);
    setState(() {
      isLoading=true;
    });
    fetchTodo();
  }

  Future<void> deleteById(String id) async {
    if (id.isEmpty) {
      print('Cannot delete item with empty ID');
      return;
    }

    // Delete the item
    final url = 'http://api.nstack.in/v1/todos/$id';
    final uri = Uri.parse(url);
    try {
      final response = await http.delete(uri);
      if (response.statusCode == 200) {
        // Remove the item from the list
        final filtered = items.where((element) => element['_id'] != id).toList();
        setState(() {
          items = filtered;
        });
      } else {
        // Handle error case here
        print('Failed to delete the item. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error occurred while deleting the item: $e');
    }
  }

  Future<void> fetchTodo() async {
    final url = 'http://api.nstack.in/v1/todos?page=1&limit=10';
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      final result = json['items'] as List;
      setState(() {
        items = result;
      });
    } else {
      // Handle error case here
    }
    setState(() {
      isLoading = false;
    });
  }
}
