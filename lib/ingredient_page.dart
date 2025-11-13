import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientPage extends StatefulWidget {
  const IngredientPage({super.key});

  @override
  State<IngredientPage> createState() => _IngredientPageState();
}

class _IngredientPageState extends State<IngredientPage> {
  final CollectionReference _ingredients = FirebaseFirestore.instance
      .collection('ingredients');

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  Future<void> _showIngredientDialog({
    String? id,
    String? name,
    num? price,
    String? unit,
  }) async {
    final bool isEdit = id != null;
    _nameController.text = name ?? '';
    _priceController.text = price?.toString() ?? '';
    _unitController.text = unit ?? 'kg';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Bahan' : 'Tambah Bahan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Bahan'),
            ),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga per unit'),
            ),
            TextField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: 'Satuan (kg, gr, dll)',
              ),
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
              final price = num.tryParse(_priceController.text.trim()) ?? 0;
              final unit = _unitController.text.trim();
              if (name.isEmpty || price == 0) return;

              if (isEdit) {
                await _ingredients.doc(id).update({
                  'name': name,
                  'price': price,
                  'unit': unit,
                });
              } else {
                await _ingredients.add({
                  'name': name,
                  'price': price,
                  'unit': unit,
                  'createdAt': Timestamp.now(),
                });
              }

              _nameController.clear();
              _priceController.clear();
              _unitController.clear();
              Navigator.pop(context);
            },
            child: Text(isEdit ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteIngredient(String id) async {
    await _ingredients.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bahan Dasar')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ingredients.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada bahan'));
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
                  subtitle: Text('Harga: ${data['price']} / ${data['unit']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showIngredientDialog(
                          id: doc.id,
                          name: data['name'],
                          price: data['price'],
                          unit: data['unit'],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteIngredient(doc.id),
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
        onPressed: () => _showIngredientDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
