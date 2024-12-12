import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../screens/recipe_screen.dart';

class RecipeItem extends StatelessWidget {
  final Recipe recipe;

  RecipeItem({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: SizedBox(
          width: 60,  // Tentukan lebar untuk gambar
          height: 60, // Tentukan tinggi untuk gambar
          child: Image.network(
            recipe.imageUrl,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                // Jika gambar sudah dimuat, tampilkan gambar
                return child;
              } else {
                // Jika gambar sedang dimuat, tampilkan CircularProgressIndicator
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
            errorBuilder: (context, error, stackTrace) {
              // Menampilkan ikon error jika gambar gagal dimuat
              return Icon(Icons.error);
            },
          ),
        ),
        title: Text(recipe.title),
        onTap: () {
          // Navigasi ke layar detail resep saat item ditekan
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeScreen(recipe: recipe),
            ),
          );
        },
      ),
    );
  }
}
