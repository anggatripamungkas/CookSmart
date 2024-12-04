import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../services/database_manager.dart';

class MealPlanScreen extends StatefulWidget {
  final List<MealPlan> mealPlans;

  MealPlanScreen({this.mealPlans = const []});

  @override
  _MealPlanScreenState createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  List<Map<String, dynamic>> _mealPlans = [];

  @override
  void initState() {
    super.initState();
    _loadMealPlans();
  }

  Future<void> _loadMealPlans() async {
    final plans = await DatabaseManager.instance.getMealPlans();
    setState(() {
      _mealPlans = plans;
    });
  }

  void _showAddOrEditMealPlanDialog({Map<String, dynamic>? mealPlan}) {
    final _dayController = TextEditingController(text: mealPlan?['day']);
    final _mealController = TextEditingController(text: mealPlan?['meals']);
    final _calorieController = TextEditingController(
        text: mealPlan?['calorie_limit'] != null
            ? mealPlan!['calorie_limit'].toString()
            : '');

    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(mealPlan == null ? 'Tambah Rencana Makan' : 'Edit Rencana Makan'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _dayController,
                    decoration: const InputDecoration(labelText: 'Hari'),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Hari tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _mealController,
                    decoration: const InputDecoration(
                        labelText: 'Makanan (pisahkan dengan koma)'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Makanan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _calorieController,
                    decoration: const InputDecoration(labelText: 'Batas Kalori (kcal)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Batas Kalori tidak boleh kosong';
                      }
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Harus angka lebih besar dari 0';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  String day = _dayController.text;
                  if (day.isNotEmpty) {
                    day = day[0].toUpperCase() + day.substring(1).toLowerCase();
                  }

                  if (mealPlan == null) {
                    await DatabaseManager.instance.insertMealPlan({
                      'day': day,
                      'meals': _mealController.text,
                      'calorie_limit': int.parse(_calorieController.text),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rencana makan berhasil ditambahkan!'),
                        backgroundColor: Colors.green, // Warna hijau untuk sukses
                      ),
                    );
                  } else {
                    await DatabaseManager.instance.updateMealPlan({
                      'id': mealPlan['id'],
                      'day': day,
                      'meals': _mealController.text,
                      'calorie_limit': int.parse(_calorieController.text),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rencana makan berhasil diperbarui!'),
                        backgroundColor: Colors.green, // Warna hijau untuk sukses
                      ),
                    );
                  }

                  Navigator.of(ctx).pop();
                  _loadMealPlans();
                }
              },
              child: const Text('Simpan'),
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
        title: const Text(
          'Meal Plan',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        elevation: 4.0,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddOrEditMealPlanDialog(),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[300],
        child: ListView.builder(
          itemCount: _mealPlans.length,
          itemBuilder: (context, index) {
            final mealPlan = _mealPlans[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(
                  mealPlan['day'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Makanan : ${mealPlan['meals']}'),
                    Text('Batas Kalori : ${mealPlan['calorie_limit']} kcal'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () =>
                          _showAddOrEditMealPlanDialog(mealPlan: mealPlan),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        // Menampilkan dialog konfirmasi sebelum menghapus
                        bool? shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Konfirmasi'),
                              content: const Text('Apakah Anda yakin ingin menghapus rencana makan ini?'),
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
                          await DatabaseManager.instance.deleteMealPlan(mealPlan['id']);
                          _loadMealPlans(); // Memuat ulang rencana makan

                          // Menampilkan pesan sukses
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rencana makan berhasil dihapus'),
                              backgroundColor: Colors.green, // Warna hijau untuk sukses
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
