import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'responsive_layout.dart';
import 'item_form_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _deleteItem(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('items').doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = FirebaseFirestore.instance
        .collection('items')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showItemFormDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: items.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No items yet. Tap + to add one.'));
          }

          return ResponsiveLayout(
            mobile: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: docs.length,
              itemBuilder: (context, i) => _ItemCard(
                doc: docs[i],
                onDelete: () => _deleteItem(context, docs[i].id),
              ),
            ),
            tablet: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 110,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: docs.length,
              itemBuilder: (context, i) => _ItemCard(
                doc: docs[i],
                onDelete: () => _deleteItem(context, docs[i].id),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final VoidCallback onDelete;

  const _ItemCard({required this.doc, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListTile(
        title: Text(data['title'] ?? ''),
        subtitle: Text(data['description'] ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.indigo),
              onPressed: () => showItemFormDialog(context, existing: doc),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}