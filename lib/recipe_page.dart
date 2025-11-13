import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final CollectionReference _recipes = FirebaseFirestore.instance.collection(
    'recipes',
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  Future<void> _showRecipeDialog({
    String? id,
    String? name,
    String? desc,
  }) async {
    final bool isEdit = id != null;
    _nameController.text = name ?? '';
    _descController.text = desc ?? '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Resep' : 'Tambah Resep'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Resep'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final desc = _descController.text.trim();
              if (name.isEmpty) return;

              if (isEdit) {
                await _recipes.doc(id).update({
                  'name': name,
                  'description': desc,
                });
              } else {
                await _recipes.add({
                  'name': name,
                  'description': desc,
                  'status': 'Belum Dibuat',
                  'createdAt': Timestamp.now(),
                });
              }

              _nameController.clear();
              _descController.clear();
              Navigator.pop(context);
            },
            child: Text(isEdit ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecipe(String id) async {
    await _recipes.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resep Masakan')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _recipes.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada resep'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['name'] ?? ''),
                  subtitle: Text(data['description'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showRecipeDialog(
                          id: doc.id,
                          name: data['name'],
                          desc: data['description'],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRecipe(doc.id),
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
        onPressed: () => _showRecipeDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
