import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference _todos = FirebaseFirestore.instance.collection(
    'todos',
  );

  Future<void> _addTodo() async {
    final String text = _controller.text.trim();
    if (text.isNotEmpty) {
      await _todos.add({'task': text, 'done': false});
      _controller.clear();
    }
  }

  Future<void> _deleteTodo(String id) async {
    await _todos.doc(id).delete();
  }

  Future<void> _toggleDone(String id, bool currentValue) async {
    await _todos.doc(id).update({'done': !currentValue});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List Firestore'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Tambahkan tugas...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTodo,
                  child: const Text('Tambah'),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _todos.snapshots(),
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
                    final done = doc['done'] as bool;

                    return ListTile(
                      title: Text(
                        todo,
                        style: TextStyle(
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      leading: Checkbox(
                        value: done,
                        onChanged: (_) => _toggleDone(doc.id, done),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTodo(doc.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
