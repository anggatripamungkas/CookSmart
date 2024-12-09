import 'dart:async';

import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import '../services/database_manager.dart';

class RecipeScreen extends StatefulWidget {
  final Recipe recipe;

  RecipeScreen({required this.recipe});

  @override
  _RecipeScreenState createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  late Future<List<String>> _ingredients = Future.value([]); // Inisialisasi dengan list kosong
  late Future<List<Map<String, dynamic>>> _instructions = Future.value([]);  // Inisialisasi dengan list kosong
  bool isFavorite = false;
  late Recipe _currentRecipe;

  @override
  void initState() {
    super.initState();
    _currentRecipe = widget.recipe; // Salin nilai awal dari widget.recipe
    _showCookingSteps(); // Menampilkan langkah-langkah memasak setelah halaman diinisialisasi

    // Mengatur default value untuk _ingredients
    _ingredients = Future.value([]);

    // Mengecek status favorit
    _isRecipeFavorite().then((favorite) {
      setState(() {
        isFavorite = favorite;
      });

      if (isFavorite) {
        // Jika resep sudah ada di favorit, ambil data dari SQLite
        _loadRecipeFromDatabase();
      } else {
        // Jika resep belum ada di favorit, ambil data dari API
        _ingredients = ApiService.fetchIngredients(widget.recipe.id);
        _instructions = ApiService.fetchInstructions(widget.recipe.id); // Ambil instruksi dari API
      }
    });
  }

  Future<void> _showCookingSteps() async {
    try {
      final db = await DatabaseManager.instance.database;
      
      // Mengambil seluruh data langkah-langkah memasak dari tabel cooking_steps
      final List<Map<String, dynamic>> cookingSteps = await db.query('cooking_steps');  // Mengambil semua data dari cooking_steps
      // Menampilkan langkah-langkah memasak di debug console
      print("Langkah-langkah Memasak (Debug):");
      cookingSteps.forEach((step) {
        print('id :${step['recipe_id']},title : ${step['recipe_title']}');
        print('Langkah ${step['step_number']}: ${step['instruction']}');
      });
    } catch (e) {
      print("Error mengambil langkah-langkah memasak: $e");
    }
}

  // Fungsi untuk mengambil data dari SQLite
  Future<void> _loadRecipeFromDatabase() async {
    try {
      // Mengecek apakah resep ada di favorit
      final favoriteData = await DatabaseManager.instance.getFavoriteByTitle(widget.recipe.title);
    
      if (favoriteData != null) {
        // Ambil langkah-langkah memasak dari database berdasarkan recipe_title yang sesuai
        final db = await DatabaseManager.instance.database;
        final List<Map<String, dynamic>> cookingSteps = await db.query(
          'cooking_steps',
          where: 'recipe_title = ?',  // Menggunakan recipe_title sebagai kondisi
          whereArgs: [widget.recipe.title],  // Menggunakan widget.recipe.title untuk mencari langkah-langkah memasak
        );

        // Format langkah-langkah memasak
        final List<Map<String, dynamic>> formattedCookingSteps = cookingSteps.map((step) {
          return {
            'step': step['step_number'].toString(),
            'instruction': step['instruction'],
          };
        }).toList();

        // Setelah data berhasil diambil, panggil setState untuk memperbarui UI
        setState(() {
          _ingredients = Future.value(favoriteData['ingredients']?.split(', ') ?? []);  // Memperbarui bahan
          _instructions = Future.value(formattedCookingSteps);  // Memperbarui instruksi
        });
      } else {
        // Jika data tidak ditemukan di database, ambil dari API
        setState(() {
          _ingredients = ApiService.fetchIngredients(widget.recipe.id);  // Ambil bahan dari API
          _instructions = ApiService.fetchInstructions(widget.recipe.id);  // Ambil instruksi dari API
        });
      }
    } catch (e) {
      print("Error loading data from database: $e");
      // Menangani error, pastikan state tetap diperbarui meskipun terjadi error
      setState(() {
        _ingredients = Future.value([]);  // Kosongkan bahan jika terjadi error
        _instructions = Future.value([]);  // Kosongkan instruksi jika terjadi error
      });
    }
  }

  // Fungsi untuk mengecek apakah resep ada di favorit
  Future<bool> _isRecipeFavorite() async {
    final favoriteList = await DatabaseManager.instance.getFavorites();
    return favoriteList.any((favorite) => favorite['title'] == widget.recipe.title);
  }

  // Fungsi untuk menambahkan bahan ke daftar belanja
  void _addToShoppingList(List<String> ingredients) async {
    try {
      for (var ingredient in ingredients) {
        await DatabaseManager.instance.insertShoppingItem({
          'recipe_name': widget.recipe.title, // Nama resep
          'ingredient': ingredient,
        });
      }

      // Menampilkan data bahan yang berhasil disimpan
      final shoppingList = await DatabaseManager.instance.getShoppingItems();
      print("Bahan berhasil disimpan ke daftar belanja:");
      shoppingList.forEach((item) {
        print(item);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bahan berhasil ditambahkan ke daftar belanja!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menambahkan ke daftar belanja.')),
      );
    }
  }

  // Fungsi untuk toggle status favorit (tambah/hapus)
  void _toggleFavorite(BuildContext context) async {
    try {
      final isFavorite = await _isRecipeFavorite();  // Mengecek apakah resep sudah ada di favorit
      if (isFavorite) {
        // Menghapus dari favorit
        await DatabaseManager.instance.deleteFavorite(widget.recipe.id);
        await DatabaseManager.instance.deleteCookingSteps(widget.recipe.id);  // Menghapus langkah memasak
        await DatabaseManager.instance.deleteShoppingItems(widget.recipe.title);  // Menghapus item belanja

        // Tampilkan notifikasi sukses menghapus
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resep berhasil dihapus dari favorit!')),
        );
        // Kembali ke halaman sebelumnya (daftar favorit)
        Navigator.pop(context, true); // true untuk refresh
      } else {
        // Cek apakah bahan dan informasi nutrisi sudah ada di database
        final existingFavorite = await DatabaseManager.instance.getFavoriteByTitle(widget.recipe.title);

        if (existingFavorite == null) {
          // Ambil bahan dan instruksi dari API jika belum ada di database
          final ingredients = await ApiService.fetchIngredients(widget.recipe.id);
          final instructions = await ApiService.fetchInstructions(widget.recipe.id);

          final recipeData = {
            'title': widget.recipe.title,
            'imageUrl': widget.recipe.imageUrl,
            'calories': widget.recipe.calories,
            'protein': widget.recipe.protein,
            'carbs': widget.recipe.carbs,
            'fat': widget.recipe.fat,
            'ingredients': ingredients.join(', '),
          };

          // Menyimpan data resep ke database
          await DatabaseManager.instance.insertFavorite(recipeData);

          // Menyimpan langkah-langkah memasak ke database
          for (var i = 0; i < instructions.length; i++) {
            // Mengecek apakah langkah sudah ada di database
            final existingStep = await DatabaseManager.instance.getCookingStepByRecipeIdAndStepNumber(
              widget.recipe.id,
              i + 1,
            );

            // Jika langkah belum ada, maka simpan
            if (existingStep == null) {
              await DatabaseManager.instance.insertCookingStep({
                'recipe_id': widget.recipe.id,
                'recipe_title': widget.recipe.title, // Tambahkan title resep
                'step_number': i + 1,
                'instruction': instructions[i]['instruction'],
              });
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resep berhasil ditambahkan ke favorit!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengubah status favorit.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRecipe.title),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        elevation: 4.0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color.fromARGB(255, 0, 242, 255),
                width: 3.0,
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.network(
                      widget.recipe.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 250,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child; // Menampilkan gambar ketika sudah selesai dimuat
                        } else {
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        }
                      },
                      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                        // Menampilkan ikon ketika gambar gagal dimuat
                        return Center(
                          child: Icon(
                            Icons.image_not_supported, // Ikon untuk gambar yang tidak ditemukan
                            size: 100,
                            color: const Color.fromARGB(255, 161, 76, 76),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Informasi Nutrisi & Bahan-Bahan :',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<String>>(
                    future: _ingredients,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(child: Text('Gagal memuat bahan-bahan.'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Tidak ada bahan tersedia.'));
                      } else {
                        final String ingredients = snapshot.data
                                ?.asMap()
                                .entries
                                .map((entry) => '${entry.key + 1}. ${entry.value}')
                                .join('\n') ?? 'Tidak ada bahan';

                        final List<Map<String, String>> data = [
                          {'label': 'Kalori', 'value': '${widget.recipe.calories} kcal'},
                          {'label': 'Protein', 'value': widget.recipe.protein},
                          {'label': 'Karbohidrat', 'value': widget.recipe.carbs},
                          {'label': 'Lemak', 'value': widget.recipe.fat},
                          {'label': 'Bahan', 'value': ingredients},
                        ];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Table(
                              border: TableBorder.all(color: Colors.grey, width: 1),
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(3),
                              },
                              children: data
                                  .map(
                                    (row) => TableRow(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            row['label']!,
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            row['value']!,
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  final ingredientsList = snapshot.data ?? [];
                                  _addToShoppingList(ingredientsList);
                                },
                                child: const Text('Tambahkan ke Daftar Belanja'),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Langkah-langkah Memasak :',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _instructions,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(child: Text('Gagal memuat langkah-langkah memasak.'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Tidak ada langkah-langkah memasak.'));
                      } else {
                        final steps = snapshot.data ?? [];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: steps.map((step) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Langkah ke ${step['step']} :', // Menampilkan nomor langkah
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      step['instruction'], // Menampilkan instruksi
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.justify,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 70),  // Menambahkan jarak di bawah konten
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () => _toggleFavorite(context),
              child: Text(isFavorite ? 'Hapus dari Favorit' : 'Tambah ke Favorit'),
            ),
          ),
        ],
      ),
    );
  }
}
