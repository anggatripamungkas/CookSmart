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
  List<String> selectedDiets = []; // Menyimpan diet yang dipilih

  // Daftar preferensi diet yang tersedia
  final List<String> dietOptions = [
    'Vegetarian',
    'Vegan',
    'Keto',
    'Gluten-Free',
  ];

  // Variabel untuk menentukan jenis pencarian (berdasarkan nama atau bahan)
  String searchType = 'name';

  // Fungsi untuk mencari resep berdasarkan nama makanan atau bahan
  Future<void> _searchRecipes() async {
    String foodName = _controller.text.trim();

    // Validasi input
    if (foodName.isEmpty && selectedDiets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan makanan atau pilih filter!')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Persiapkan parameter pencarian berdasarkan kondisi
      final recipes = await ApiService.fetchRecipes(
        foodName.isEmpty ? null : foodName, // Null jika input makanan kosong
        diet: selectedDiets.isEmpty ? null : selectedDiets.join(','), // Null jika filter diet kosong
        searchType: searchType,
      );

      if (recipes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada resep ditemukan!')),
        );
      }

      setState(() {
        _recipes = recipes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
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
      searchType = 'name'; // Reset ke pencarian nama makanan
      isLoading = false;
    });
  }

  // Fungsi untuk menampilkan dialog filter preferensi diet
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Pilih Preferensi Diet'),
              content: SingleChildScrollView(
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Fungsi untuk menampilkan dialog pilih jenis pencarian (berdasarkan nama atau bahan)
  void _showSearchTypeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Jenis Pencarian'),
          content: SingleChildScrollView(  // Membungkus Column dengan SingleChildScrollView
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Berdasarkan Nama Makanan'),
                  leading: Radio<String>(
                    value: 'name',
                    groupValue: searchType,
                    onChanged: (value) {
                      setState(() {
                        searchType = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Berdasarkan Bahan-bahan'),
                  leading: Radio<String>(
                    value: 'ingredients',
                    groupValue: searchType,
                    onChanged: (value) {
                      setState(() {
                        searchType = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
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
        title: const Text('Cari Resep', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
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
        color: Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                enabled: !isLoading,
                decoration: InputDecoration(
                  hintText: searchType == 'name'
                      ? 'Misal: fried rice atau beef rendang'
                      : 'Misal: Broccoli, eggs',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _controller.clear,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _showSearchTypeDialog,
                    child: const Text('Jenis Pencarian'),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ? null : _searchRecipes,
                    child: const Text('Cari'),
                  ),
                  ElevatedButton(
                    onPressed: _resetRecipes,
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_recipes.isEmpty && !_controller.text.isEmpty)
                const Center(child: Text('Tidak ada resep yang ditemukan.'))
              else if (_recipes.isEmpty && _controller.text.isEmpty)
                const Center(child: Text(''))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      return RecipeItem(recipe: _recipes[index]);
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