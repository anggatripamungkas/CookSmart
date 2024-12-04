import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class ApiService {
  static const String _apiKey = 'ad40bb97abf2447895592becf70d6967';  // Ganti dengan kunci API Anda yang valid
  static const String _baseUrl = 'https://api.spoonacular.com';

  // Fungsi untuk mengonversi nilai nutrisi yang bertipe String ke int
  static int _parseToInt(dynamic value) {
    if (value is String) {
      // Menghapus karakter non-angka (seperti "g" atau "kcal")
      final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), ''); 
      return int.tryParse(cleanedValue) ?? 0;  // Mengonversi ke int, jika gagal kembalikan 0
    } else if (value is int) {
      return value;
    }
    return 0;  // Mengembalikan 0 jika tipe data tidak sesuai
  }

  // Fungsi untuk mengambil resep berdasarkan bahan dan diet
  static Future<List<Recipe>> fetchRecipes(List<String> ingredients, {String? diet}) async {
    final String ingredientsString = ingredients.join(',');

    // Menggunakan complexSearch untuk memungkinkan penggunaan filter diet
    final String dietParam = diet != null ? '&diet=$diet' : '';
    final String url =
        '$_baseUrl/recipes/complexSearch?ingredients=$ingredientsString&number=3&apiKey=$_apiKey$dietParam';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'];

        // Untuk setiap resep, kita ambil juga informasi nutrisi
        List<Recipe> recipes = [];
        for (var recipeData in data) {
          var recipe = Recipe.fromJson(recipeData);

          // Ambil informasi nutrisi tambahan dari API (kalori, protein, karbohidrat, lemak)
          var nutrition = await fetchNutrients(recipe.id);

          // Update resep dengan informasi nutrisi
          recipe = recipe.copyWith(
            calories: nutrition['calories'],
            protein: nutrition['protein'],
            carbs: nutrition['carbs'],
            fat: nutrition['fat'],
          );
          recipes.add(recipe);
        }
        return recipes;
      } else {
        throw Exception('Gagal memuat resep. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat memuat resep: $e');
    }
  }

  // Fungsi untuk mengambil informasi nutrisi dari Spoonacular
  static Future<Map<String, dynamic>> fetchNutrients(int recipeId) async {
    final url = Uri.parse('$_baseUrl/recipes/$recipeId/nutritionWidget.json?apiKey=$_apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Pastikan untuk mengonversi kalori ke integer, sementara nutrisi lainnya tetap string dengan satuannya
      return {
        'calories': _parseToInt(data['calories']),
        'protein': data['protein'],  // Biarkan sebagai string dengan "g"
        'carbs': data['carbs'],      // Biarkan sebagai string dengan "g"
        'fat': data['fat'],          // Biarkan sebagai string dengan "g"
      };
    } else {
      throw Exception('Gagal mengambil informasi nutrisi. Status code: ${response.statusCode}');
    }
  }
  
    // Fungsi untuk mengambil daftar bahan-bahan dari Spoonacular
  static Future<List<String>> fetchIngredients(int recipeId) async {
    final url = Uri.parse('$_baseUrl/recipes/$recipeId/ingredientWidget.json?apiKey=$_apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['ingredients'] as List)
          .map((ingredient) => ingredient['name'] as String)
          .toList();
    } else {
      throw Exception('Gagal mengambil daftar bahan-bahan.');
    }
  }

  // Fungsi untuk mengambil instruksi resep
  static Future<List<Map<String, String>>> fetchInstructions(int recipeId) async {
    final url = Uri.parse('$_baseUrl/recipes/$recipeId/analyzedInstructions?apiKey=$_apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Mengubah data menjadi daftar langkah dengan nomor langkah dan instruksi
      return (data as List)
          .expand((instruction) => instruction['steps'] as List)
          .map((step) => {
            'step': (step['number'] as int).toString(),  // Mengambil nomor langkah
            'instruction': step['step'] as String,      // Mengambil instruksi
          })
          .toList();
    } else {
      throw Exception('Gagal mengambil instruksi.');
    }
  }
}
