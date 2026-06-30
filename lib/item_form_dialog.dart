import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> showItemFormDialog(BuildContext context, {DocumentSnapshot? existing}) {
  final titleController = TextEditingController(text: existing?['title'] ?? '');
  final descController = TextEditingController(text: existing?['description'] ?? '');
  final formKey = GlobalKey<FormState>();
  final isEditing = existing != null;

  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(isEditing ? 'Edit Item' : 'Add Item'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final data = {
                'title': titleController.text.trim(),
                'description': descController.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              };
              final items = FirebaseFirestore.instance.collection('items');
              if (isEditing) {
                await items.doc(existing.id).update(data);
              } else {
                await items.add({
                  ...data,
                  'createdBy': FirebaseAuth.instance.currentUser!.uid,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      );
    },
  );
}