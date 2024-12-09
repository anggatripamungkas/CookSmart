import 'package:flutter/material.dart';
import '../services/database_manager.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  Future<List<Map<String, dynamic>>>? _shoppingItems;

  @override
  void initState() {
    super.initState();
    _loadShoppingItems();
  }

  void _loadShoppingItems() {
    setState(() {
      _shoppingItems = DatabaseManager.instance.getShoppingItems();
    });
    _shoppingItems?.then((items) {
      print("Loaded items: $items");
    });
  }

  void _markAsBought(int id, bool isChecked) async {
    await DatabaseManager.instance.markAsBought(id, isChecked ? 1 : 0);
    _loadShoppingItems();
  }

  void _deleteItem(int id) async {
    // Menampilkan dialog konfirmasi sebelum menghapus
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin menghapus bahan belanja ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Pengguna membatalkan penghapusan
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Pengguna mengonfirmasi penghapusan
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      // Lanjutkan penghapusan jika pengguna mengonfirmasi
      await DatabaseManager.instance.deleteShoppingItem(id);
      _loadShoppingItems(); // Memuat ulang daftar belanja

      // Menampilkan pesan sukses setelah berhasil dihapus
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bahan berhasil dihapus'),
          backgroundColor: Colors.green, // Warna hijau untuk sukses
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Daftar Belanja',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        elevation: 4.0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color.fromARGB(255, 0, 242, 255),
                width: 3.0,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[300],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bahan-Bahan yang Perlu Dibeli: ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _shoppingItems,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(
                        child: Text('Gagal memuat daftar belanja.'),
                      );
                    } else {
                      final items = snapshot.data ?? [];
                      return items.isEmpty
                          ? const Center(
                              child: Text(
                                'Daftar belanja kosong.',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  color: Colors.white,  // Set background color white
                                  child: ListTile(
                                    title: Text(item['ingredient']),
                                    subtitle: Text('Resep: ${item['recipe_name']}'),
                                    leading: Checkbox(
                                      value: item['is_checked'] == 1,
                                      onChanged: (bool? value) {
                                        if (value != null) {
                                          _markAsBought(item['id'], value);
                                        }
                                      },
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        _deleteItem(item['id']);
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
