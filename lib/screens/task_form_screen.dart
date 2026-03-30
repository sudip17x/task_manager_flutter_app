import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task; // Null means create new

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _dueDate;
  late String _status;
  String? _blockedBy;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _dueDate = widget.task?.dueDate ?? DateTime.now();
    _status = widget.task?.status ?? 'To-Do';
    _blockedBy = widget.task?.blockedBy;

    if (widget.task == null) {
      _loadDraft();
    }
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _titleController.text = prefs.getString('draft_title') ?? '';
      _descriptionController.text = prefs.getString('draft_desc') ?? '';
      _status = prefs.getString('draft_status') ?? 'To-Do';
      
      final dateMillis = prefs.getInt('draft_date');
      if (dateMillis != null) {
        _dueDate = DateTime.fromMillisecondsSinceEpoch(dateMillis);
      }
      _blockedBy = prefs.getString('draft_blockedBy');
    });
  }

  Future<void> _saveDraft() async {
    if (widget.task != null) return; // Don't save draft for edits
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_title', _titleController.text);
    await prefs.setString('draft_desc', _descriptionController.text);
    await prefs.setString('draft_status', _status);
    await prefs.setInt('draft_date', _dueDate.millisecondsSinceEpoch);
    if (_blockedBy != null) {
      await prefs.setString('draft_blockedBy', _blockedBy!);
    } else {
      await prefs.remove('draft_blockedBy');
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_title');
    await prefs.remove('draft_desc');
    await prefs.remove('draft_status');
    await prefs.remove('draft_date');
    await prefs.remove('draft_blockedBy');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
      _saveDraft();
    }
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final provider = Provider.of<TaskProvider>(context, listen: false);
    if (provider.isLoading) return;

    final task = Task(
      id: widget.task?.id ?? const Uuid().v4(),
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _dueDate,
      status: _status,
      blockedBy: _blockedBy,
    );

    if (widget.task == null) {
      await provider.addTask(task);
      await _clearDraft();
    } else {
      await provider.updateTask(task);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task Saved Successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    // Tasks cannot block themselves
    final availableTasks = provider.tasks.where((t) => t.id != widget.task?.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => _saveDraft(),
                    validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                    onChanged: (_) => _saveDraft(),
                    validator: (val) => val == null || val.isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: const Text('Due Date'),
                    subtitle: Text(DateFormat.yMd().format(_dueDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: provider.isLoading ? null : _selectDate,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['To-Do', 'In Progress', 'Done']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: provider.isLoading ? null : (val) {
                      if (val != null) {
                        setState(() => _status = val);
                        _saveDraft();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: _blockedBy,
                    decoration: InputDecoration(
                      labelText: 'Blocked By (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...availableTasks.map((t) => DropdownMenuItem(value: t.id, child: Text(t.title))),
                    ],
                    onChanged: provider.isLoading ? null : (val) {
                      setState(() => _blockedBy = val);
                      _saveDraft();
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: provider.isLoading ? null : _saveTask,
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            widget.task == null ? 'Create Task' : 'Update Task',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (provider.isLoading)
            Container(
              color: Colors.black12,
            ),
        ],
      ),
    );
  }
}
