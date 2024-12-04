import 'package:flutter/material.dart';
import '../widgets/recipe_item.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Recipe> _recipes = [];
  bool isLoading = false;
  List<String> selectedDiets = []; // Untuk menyimpan diet yang dipilih

  // Daftar preferensi diet yang tersedia
  final List<String> dietOptions = [
    'Vegetarian',
    'Vegan',
    'Keto',
    'Gluten-Free',
  ];

  // Fungsi untuk mencari resep berdasarkan bahan dan diet
  void _searchRecipes() async {
    String ingredients = _controller.text;

    // Jika bahan kosong dan tidak ada diet yang dipilih, tampilkan pesan
    if (ingredients.isEmpty && selectedDiets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan bahan atau pilih filter!')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Panggil API Service untuk mendapatkan resep
      final recipes = await ApiService.fetchRecipes(
        ingredients.isNotEmpty ? ingredients.split(',') : [],  // Bahan yang dimasukkan, kosongkan jika bahan kosong
        diet: selectedDiets.join(','),  // Diet yang dipilih
      );

      if (recipes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada resep ditemukan!')),
        );
      }

      setState(() {
        _recipes = recipes;
      });
    } catch (e, stackTrace) {
      debugPrint('Error saat mencari resep: $e');
      debugPrint('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fungsi untuk mereset data resep dan kolom pencarian
  void _resetRecipes() {
    setState(() {
      _recipes = [];
      _controller.clear();
      selectedDiets = [];
    });
  }

  // Fungsi untuk menampilkan dialog filter
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Pilih Preferensi Diet'),
              content: SingleChildScrollView( // Membungkus dengan SingleChildScrollView
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: dietOptions.map((diet) {
                    return CheckboxListTile(
                      title: Text(diet),
                      value: selectedDiets.contains(diet),
                      onChanged: (isChecked) {
                        setStateDialog(() {
                          if (isChecked == true) {
                            selectedDiets.add(diet);
                          } else {
                            selectedDiets.remove(diet);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup dialog
                  },
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Cari Resep',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
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
        color: Colors.grey[300],
        height: double.infinity,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masukkan Bahan-Bahan :',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Misal: Fish,tomato,spinach',
                              border: OutlineInputBorder(),
                              filled: true, // Tambahkan properti ini
                              fillColor: Colors.white, // Latar belakang putih
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _showFilterDialog,
                          child: const Text('Filter'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _searchRecipes,
                      child: const Text('Cari'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _resetRecipes,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      return RecipeItem(recipe: _recipes[index]);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
