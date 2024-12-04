import 'package:flutter/material.dart';
import '../services/database_manager.dart';
import '../models/recipe.dart';
import 'recipe_screen.dart'; // Import RecipeScreen

class FavoriteScreen extends StatefulWidget {
  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<Map<String, dynamic>> favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites(); // Memuat favorit saat halaman pertama kali dibuka
  }

  // Memuat resep favorit dari database
  void _loadFavorites() async {
    final List<Map<String, dynamic>> favoriteList = await DatabaseManager.instance.getFavorites();
    setState(() {
      favorites = favoriteList; // Memperbarui state dengan data favorit
    });
  }

  // Menghapus resep dari favorit dengan konfirmasi
  void _removeFromFavorites(int id) async {
    // Menampilkan dialog konfirmasi sebelum menghapus
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin menghapus resep ini dari favorit?'),
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

    // Jika pengguna mengonfirmasi penghapusan, lanjutkan proses penghapusan
    if (shouldDelete == true) {
      await DatabaseManager.instance.deleteFavorite(id); // Menghapus favorit berdasarkan id
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resep berhasil dihapus dari favorit!')),
      );
      _loadFavorites(); // Memuat ulang daftar favorit setelah penghapusan
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black, // Latar belakang AppBar hitam
        foregroundColor: Colors.white, // Teks dan ikon putih
        title: const Text('Favorites', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: const Color.fromARGB(255, 0, 242, 255),
                width: 3.0,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[300], // Latar belakang abu-abu terang
        height: double.infinity, // Memastikan tinggi mengisi layar
        child: favorites.isEmpty
            ? const Center(
                child: Text(
                  'Belum ada resep di favorit!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            : ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final favorite = favorites[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0), // Rounded corners for the card
                    ),
                    elevation: 4.0, // Card shadow for a more prominent look
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12.0),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0), // Rounded image corners
                        child: Image.network(
                          favorite['imageUrl'],
                          width: 60, // Size of the image
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        favorite['title'],
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () async {
                        // Navigasi ke halaman detail resep saat ditekan
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeScreen(
                              recipe: Recipe(
                                id: favorite['id'],
                                title: favorite['title'],
                                imageUrl: favorite['imageUrl'],
                                instructions: favorite['instructions'] ?? 'No instructions',
                                calories: favorite['calories'] ?? 0,
                                protein: favorite['protein'] ?? 0,
                                carbs: favorite['carbs'] ?? 0,
                                fat: favorite['fat'] ?? 0,
                              ),
                            ),
                          ),
                        );
                        // Jika ada perubahan (result bernilai true), refresh daftar favorit
                        if (result == true) {
                          _loadFavorites();
                        }
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Menghapus item dari favorit saat tombol hapus ditekan
                          _removeFromFavorites(favorite['id']);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
