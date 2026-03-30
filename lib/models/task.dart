import 'package:hive/hive.dart';

class Task {
  String id;
  String title;
  String description;
  DateTime dueDate;
  String status; // 'To-Do', 'In Progress', 'Done'
  String? blockedBy;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedBy,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    String? blockedBy,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedBy: blockedBy ?? this.blockedBy,
    );
  }
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    return Task(
      id: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      dueDate: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      status: reader.readString(),
      blockedBy: reader.read() as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.description);
    writer.writeInt(obj.dueDate.millisecondsSinceEpoch);
    writer.writeString(obj.status);
    writer.write(obj.blockedBy);
  }
}
