import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final CollectionReference _todos = FirebaseFirestore.instance.collection(
    'todos',
  );

  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  /// Fungsi menentukan status berdasarkan tanggal
  String _getAutoStatus(DateTime start, DateTime end) {
    final now = DateTime.now();
    if (now.isBefore(start)) return 'Belum dimulai';
    if (now.isAfter(end)) return 'Selesai';
    return 'Progres';
  }

  /// Popup tambah / edit to-do
  Future<void> _showTodoDialog({
    String? id,
    String? currentTask,
    String? currentDesc,
    DateTime? currentStart,
    DateTime? currentEnd,
  }) async {
    final bool isEdit = id != null;
    _taskController.text = currentTask ?? '';
    _descController.text = currentDesc ?? '';
    _startDate = currentStart ?? DateTime.now();
    _endDate = currentEnd ?? DateTime.now().add(const Duration(days: 1));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Tugas' : 'Tambah Tugas'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _taskController,
                decoration: const InputDecoration(
                  labelText: 'Nama Tugas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(
                        'Mulai: ${DateFormat('dd MMM yyyy').format(_startDate!)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate!,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _startDate = picked);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(
                        'Selesai: ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate!,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _endDate = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _taskController.clear();
              _descController.clear();
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final task = _taskController.text.trim();
              final desc = _descController.text.trim();
              if (task.isEmpty) return;

              final status = _getAutoStatus(_startDate!, _endDate!);

              if (isEdit) {
                await _todos.doc(id).update({
                  'task': task,
                  'desc': desc,
                  'startDate': _startDate,
                  'endDate': _endDate,
                  'status': status,
                });
              } else {
                await _todos.add({
                  'task': task,
                  'desc': desc,
                  'startDate': _startDate,
                  'endDate': _endDate,
                  'status': status,
                });
              }

              _taskController.clear();
              _descController.clear();
              Navigator.pop(context);
            },
            child: Text(isEdit ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  /// Hapus to-do
  Future<void> _deleteTodo(String id) async {
    await _todos.doc(id).delete();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Selesai':
        return Colors.green;
      case 'Progres':
        return Colors.orange;
      case 'Belum dimulai':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List Firestore'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _todos.orderBy('startDate').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs;
          if (data.isEmpty) {
            return const Center(child: Text('Belum ada tugas'));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final doc = data[index];
              final todo = doc['task'];
              final desc = doc['desc'] ?? '-';
              final start = (doc['startDate'] as Timestamp).toDate();
              final end = (doc['endDate'] as Timestamp).toDate();
              final status = doc['status'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Center(
                    child: Column(
                      children: [
                        Text(
                          todo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _statusColor(status)),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: _statusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.orangeAccent,
                        ),
                        onPressed: () => _showTodoDialog(
                          id: doc.id,
                          currentTask: todo,
                          currentDesc: desc,
                          currentStart: start,
                          currentEnd: end,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteTodo(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () => _showTodoDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
