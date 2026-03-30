import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: provider.onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search tasks...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: provider.selectedStatus,
                          items: ['All', 'To-Do', 'In Progress', 'Done']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              provider.setFilterStatus(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: provider.filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              provider.tasks.isEmpty ? "No tasks yet 🚀" : "No matches found 🔍", 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.tasks.isEmpty ? "Start by adding your first task!" : "Try a different search or filter.", 
                              style: TextStyle(color: Colors.grey[600])
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.filteredTasks.length,
                        itemBuilder: (context, index) {
                          return TaskCard(task: provider.filteredTasks[index]);
                        },
                      ),
              ),
            ],
          ),
          if (provider.isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: provider.isLoading
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TaskFormScreen()),
                );
              },
        child: const Icon(Icons.add),
      ),
    );
  }
}
