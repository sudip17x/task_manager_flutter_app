import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../screens/task_form_screen.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  Color _getStatusColor() {
    switch (task.status) {
      case 'Done':
        return Colors.green;
      case 'In Progress':
        return Colors.amber;
      case 'To-Do':
      default:
        return Colors.red;
    }
  }

  Widget _buildHighlightedText(String text, String query, {TextStyle? style}) {
    if (query.isEmpty) return Text(text, style: style);
    
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    if (!lowerText.contains(lowerQuery)) return Text(text, style: style);
    
    final startIndex = lowerText.indexOf(lowerQuery);
    final endIndex = startIndex + query.length;
    
    return RichText(
      text: TextSpan(
        style: style ?? const TextStyle(color: Colors.black),
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: const TextStyle(backgroundColor: Colors.yellow, color: Colors.black),
          ),
          TextSpan(text: text.substring(endIndex)),
        ],
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, TaskProvider provider) async {
    if (provider.isTaskUsedAsDependency(task.id)) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Warning'),
          content: const Text('This task is blocking other tasks. Deleting it will remove the dependency constraint for those tasks. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    await provider.deleteTask(task.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final isBlocked = provider.isTaskBlocked(task);

    return Opacity(
      opacity: isBlocked ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (isBlocked) const Padding(padding: EdgeInsets.only(right: 8.0), child: Icon(Icons.lock, size: 18, color: Colors.grey)),
                        Expanded(
                          child: _buildHighlightedText(
                            task.title,
                            provider.searchQuery,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.status,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              _buildHighlightedText(task.description, provider.searchQuery),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Due: ${DateFormat.yMd().format(task.dueDate)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: isBlocked || provider.isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TaskFormScreen(task: task),
                                  ),
                                );
                              },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: provider.isLoading
                            ? null
                            : () => _handleDelete(context, provider),
                      ),
                    ],
                  ),
                ],
              ),
              if (task.blockedBy != null && task.blockedBy!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Blocked by Task ID: ${task.blockedBy}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
