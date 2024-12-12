import 'package:flutter/material.dart';
import '../services/database_manager.dart';
import 'meal_plan_detail_screen.dart';

class MealPlanScreen extends StatefulWidget {
  @override
  _MealPlanScreenState createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  Map<String, List<Map<String, dynamic>>> _groupedMealPlans = {};
  Map<String, int> _calorieSums = {};
  List<Map<String, dynamic>> _favoriteRecipes = []; // Daftar resep favorit
  String? _selectedRecipeTitle; // Menyimpan resep yang dipilih

  @override
  void initState() {
    super.initState();
    _loadMealPlans();
    _loadFavorites(); // Memuat resep favorit
  }

  // Memuat resep favorit dari database
  Future<void> _loadFavorites() async {
    final favoriteList = await DatabaseManager.instance.getFavorites();
    setState(() {
      _favoriteRecipes = favoriteList;
    });
  }

  Future<void> _loadMealPlans() async {
    final plans = await DatabaseManager.instance.getMealPlans();

    Map<String, List<Map<String, dynamic>>> grouped = {};
    Map<String, int> calorieSums = {};

    for (var plan in plans) {
      String day = plan['day'];
      if (!grouped.containsKey(day)) {
        grouped[day] = [];
        calorieSums[day] = 0;
      }
      grouped[day]?.add(plan);

      // Pastikan untuk meng-cast calorie_limit ke int
      calorieSums[day] = calorieSums[day]! + (plan['calorie_limit'] as num).toInt();
    }

    // Urutkan berdasarkan hari
    List<String> orderedDays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

    // Urutkan _groupedMealPlans dan _calorieSums berdasarkan urutan hari
    Map<String, List<Map<String, dynamic>>> sortedGroupedMealPlans = {};
    Map<String, int> sortedCalorieSums = {};

    for (var day in orderedDays) {
      if (grouped.containsKey(day)) {
        sortedGroupedMealPlans[day] = grouped[day]!;
        sortedCalorieSums[day] = calorieSums[day]!;
      }
    }

    setState(() {
      _groupedMealPlans = sortedGroupedMealPlans;
      _calorieSums = sortedCalorieSums;
    });
  }

  // Menampilkan dialog untuk menambahkan meal plan
  void _showAddMealPlanDialog() async {
    String selectedDay = 'Senin'; // Hari default
    String? selectedRecipeTitle = _selectedRecipeTitle; // Menyimpan resep yang dipilih

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Tambah Meal Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              textBaseline: TextBaseline.alphabetic,
            ),
            textAlign: TextAlign.center,
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dropdown untuk memilih hari
                    DropdownButton<String>(
                      value: selectedDay,
                      onChanged: (newDay) {
                        setStateDialog(() {
                          selectedDay = newDay!;
                        });
                      },
                      items: ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu']
                          .map<DropdownMenuItem<String>>((String day) {
                        return DropdownMenuItem<String>(value: day, child: Text(day));
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    // Dropdown untuk memilih resep favorit
                    if (_favoriteRecipes.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal, // Menambahkan scroll horizontal
                        child: DropdownButton<String>(
                          hint: const Text('Pilih resep favorit'),
                          value: selectedRecipeTitle,
                          onChanged: (String? newRecipe) {
                            setStateDialog(() {
                              selectedRecipeTitle = newRecipe;
                              _selectedRecipeTitle = newRecipe;
                            });
                          },
                          items: _favoriteRecipes.map<DropdownMenuItem<String>>((recipe) {
                            return DropdownMenuItem<String>(
                              value: recipe['title'],
                              child: Text(recipe['title']),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Menutup dialog tanpa menyimpan
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black, // Mengatur warna teks menjadi hitam
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedRecipeTitle != null && selectedRecipeTitle!.isNotEmpty) {
                  // Periksa apakah meal plan sudah ada
                  final mealPlans = await DatabaseManager.instance.getMealPlans();
                  final isDuplicate = mealPlans.any((plan) =>
                      plan['day'] == selectedDay && plan['meals'] == selectedRecipeTitle);

                  if (isDuplicate) {
                    // Tampilkan pesan jika duplikat
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Makanan "$selectedRecipeTitle" sudah ada di hari $selectedDay!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Ambil kalori dari database berdasarkan title
                  int? calories = await DatabaseManager.instance.getCaloriesByTitle(selectedRecipeTitle!);

                  if (calories != null) {
                    // Menambahkan meal plan dengan nilai kalori dari database
                    await DatabaseManager.instance.insertMealPlan({
                      'day': selectedDay,
                      'meals': selectedRecipeTitle!, // Menyimpan nama resep yang dipilih
                      'calorie_limit': calories, // Menyimpan nilai kalori dari database
                    });

                    // Memuat ulang meal plans setelah ditambahkan
                    _loadMealPlans();

                    // Tampilkan SnackBar dengan konfirmasi bahwa meal plan berhasil ditambahkan
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$selectedRecipeTitle berhasil ditambahkan ke hari $selectedDay.'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    Navigator.pop(context); // Menutup dialog
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal mendapatkan data kalori dari database.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harap pilih resep favorit atau ketikkan nama resep'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black, // Mengatur warna teks menjadi hitam
              ),
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menghapus meal plan berdasarkan hari
  Future<void> _deleteMealPlan(String day) async {
    var mealPlans = await DatabaseManager.instance.getMealPlans();

    var mealPlansToDelete = mealPlans.where((plan) => plan['day'] == day).toList();

    if (mealPlansToDelete.isNotEmpty) {
      for (var plan in mealPlansToDelete) {
        int idToDelete = plan['id'];
        await DatabaseManager.instance.deleteMealPlan(idToDelete);
      }

      _loadMealPlans();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meal Plan untuk hari $day berhasil dihapus!'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal Plan tidak ditemukan untuk hari ini!'),
          backgroundColor: Color.fromARGB(255, 255, 162, 0),
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
          'Meal Plan',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddMealPlanDialog, // Menampilkan dialog untuk menambah meal plan
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[300],
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListView(
          children: _groupedMealPlans.keys.map((day) {
            final meals = _groupedMealPlans[day] ?? [];
            final calorieSum = _calorieSums[day] ?? 0;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MealPlanDetailScreen(
                      day: day,
                      meals: meals,
                      onMealPlanUpdated: () {
                        _loadMealPlans(); // Memuat ulang data meal plan
                      },
                    ),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22.0,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Total Kalori: $calorieSum kcal',
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Hapus Meal Plan'),
                                    content: Text('Apakah Anda yakin ingin menghapus meal plan untuk hari $day?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          _deleteMealPlan(day);
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
