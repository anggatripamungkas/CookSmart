import 'package:flutter/material.dart';

class ShoppingItem extends StatelessWidget {
  final String ingredient;

  ShoppingItem({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
      leading: const Icon(Icons.check_circle_outline, color: Colors.green),
      title: Text(ingredient),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          // Aksi untuk menghapus item dari daftar belanja
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$ingredient dihapus dari daftar belanja')),
          );
          // Di sini, Anda bisa mengimplementasikan logika untuk menghapus bahan dari daftar
        },
      ),
    );
  }
}
