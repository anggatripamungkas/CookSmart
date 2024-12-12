import 'package:flutter/material.dart';
import 'package:aplikasi_resep_masakan/services/database_manager.dart';

class MealPlanDetailScreen extends StatefulWidget {
  final String day;
  final List<Map<String, dynamic>> meals;
  final VoidCallback? onMealPlanUpdated; // Callback untuk memperbarui data

  const MealPlanDetailScreen({
    required this.day,
    required this.meals,
    this.onMealPlanUpdated,
  });

  @override
  _MealPlanDetailScreenState createState() => _MealPlanDetailScreenState();
}

class _MealPlanDetailScreenState extends State<MealPlanDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Meal Plan Details - ${widget.day}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
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
        padding: const EdgeInsets.all(16.0),
        child: widget.meals.isNotEmpty
            ? GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: widget.meals.length,
                itemBuilder: (context, index) {
                  final meal = widget.meals[index];
                  return Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<String?>(
                            future: DatabaseManager.instance.getImageUrlByTitle(meal['meals']),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Icon(
                                  Icons.fastfood,
                                  size: 40,
                                  color: Colors.orange,
                                );
                              }
                              if (snapshot.hasData && snapshot.data != null) {
                                return Image.network(
                                  snapshot.data!,
                                  width: 40, // Ukuran kecil
                                  height: 40, // Ukuran kecil
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Color.fromARGB(255, 94, 93, 93),
                                    );
                                  },
                                );
                              }
                              // Jika tidak ada gambar, tampilkan ikon default
                              return const Icon(
                                Icons.fastfood,
                                size: 40,
                                color: Colors.orange,
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          Text(
                            meal['meals'],
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kalori: ${meal['calorie_limit']} kcal',
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.black54,
                            ),
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton(
                              onPressed: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Konfirmasi Hapus'),
                                    content: Text('Apakah Anda yakin ingin menghapus "${meal['meals']}" dari rencana makan hari ${widget.day} ini?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Batal'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldDelete == true && index < widget.meals.length) {
                                  // Menghapus meal plan berdasarkan title dan day dari database
                                  await DatabaseManager.instance.deleteMealPlanByTitleAndDay(meal['meals'], widget.day);
                                  setState(() {
                                    widget.meals.removeAt(index);
                                  });

                                  // Tampilkan SnackBar sebagai konfirmasi penghapusan
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('"${meal['meals']}" berhasil dihapus dari rencana makan hari ${widget.day}.'),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );

                                  // Panggil callback untuk memperbarui data di layar utama
                                  if (widget.onMealPlanUpdated != null) {
                                    widget.onMealPlanUpdated!();
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(189, 234, 73, 61),
                                minimumSize: const Size(60, 30),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                              ),
                              child: const Text(
                                'Hapus',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : const Center(
                child: Text(
                  'Belum ada rencana makan untuk hari ini.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
      ),
    );
  }
}
