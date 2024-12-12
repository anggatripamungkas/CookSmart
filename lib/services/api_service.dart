import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class ApiService {
  static const String _apiKey = 'cc444476efcc41f7a9595ba9551611ad'; // Ganti dengan API key Anda
  static const String _baseUrl = 'https://api.spoonacular.com';

  static int _parseToInt(dynamic value) {
    if (value is String) {
      final cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(cleanedValue) ?? 0;
    } else if (value is int) {
      return value;
    }
    return 0;
  }

  static Future<List<Recipe>> fetchRecipes(
    String? query, {
    String? diet,
    required String searchType,
  }) async {
    String combinedParams;

    try {
      if ((query == null || query.isEmpty) && (diet != null && diet.isNotEmpty)) {
        combinedParams = 'diet=$diet';
      } else if ((query != null && query.isNotEmpty) && (diet == null || diet.isEmpty)) {
        combinedParams = searchType == 'name'
            ? 'query=$query'
            : 'includeIngredients=$query';
      } else if ((query != null && query.isNotEmpty) && (diet != null && diet.isNotEmpty)) {
        final queryParam = searchType == 'name'
            ? 'query=$query'
            : 'includeIngredients=$query';
        combinedParams = '$queryParam&diet=$diet';
      } else {
        throw Exception('Masukkan pencarian makanan atau pilih filter diet.');
      }

      final String url =
          '$_baseUrl/recipes/complexSearch?$combinedParams&number=5&apiKey=$_apiKey';

      print("Request URL: $url"); // Log URL

      final response = await http.get(Uri.parse(url));
      print("Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Response Data: $data"); // Log response data untuk debug

        if (data['results'] == null) return [];

        List<Recipe> recipes = [];
        for (var recipeData in data['results']) {
          try {
            var recipe = Recipe.fromJson(recipeData);
            var nutrition = await fetchNutrients(recipe.id);

            recipe = recipe.copyWith(
              calories: nutrition['calories'],
              protein: nutrition['protein'],
              carbs: nutrition['carbs'],
              fat: nutrition['fat'],
            );
            recipes.add(recipe);
          } catch (e) {
            print("Error parsing recipe data: $e");
          }
        }
        return recipes;
      } else {
        print("Error Response Body: ${response.body}");
        throw Exception('Gagal memuat resep. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in fetchRecipes: $e");
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchNutrients(int recipeId) async {
    final url =
        Uri.parse('$_baseUrl/recipes/$recipeId/nutritionWidget.json?apiKey=$_apiKey');
    print("Fetching Nutrients URL: $url"); // Log URL Nutrisi

    try {
      final response = await http.get(url);
      print("Nutrients Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Nutrients Data: $data"); // Log data nutrisi

        return {
          'calories': _parseToInt(data['calories']),
          'protein': data['protein'],
          'carbs': data['carbs'],
          'fat': data['fat'],
        };
      } else {
        print("Error Nutrients Response Body: ${response.body}");
        throw Exception('Gagal mengambil informasi nutrisi.');
      }
    } catch (e) {
      print("Error in fetchNutrients: $e");
      throw Exception('Kesalahan saat mengambil informasi nutrisi: $e');
    }
  }

  static Future<List<String>> fetchIngredients(int recipeId) async {
    final url =
        Uri.parse('$_baseUrl/recipes/$recipeId/ingredientWidget.json?apiKey=$_apiKey');
    print("Fetching Ingredients URL: $url"); // Log URL Bahan

    try {
      final response = await http.get(url);
      print("Ingredients Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Ingredients Data: $data"); // Log data bahan

        return (data['ingredients'] as List)
            .map((ingredient) => ingredient['name'] as String)
            .toList();
      } else {
        print("Error Ingredients Response Body: ${response.body}");
        throw Exception('Gagal mengambil daftar bahan.');
      }
    } catch (e) {
      print("Error in fetchIngredients: $e");
      throw Exception('Kesalahan saat mengambil daftar bahan: $e');
    }
  }

  static Future<List<Map<String, String>>> fetchInstructions(int recipeId) async {
    final url =
        Uri.parse('$_baseUrl/recipes/$recipeId/analyzedInstructions?apiKey=$_apiKey');
    print("Fetching Instructions URL: $url"); // Log URL Instruksi

    try {
      final response = await http.get(url);
      print("Instructions Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Instructions Data: $data"); // Log data instruksi

        if (data is! List || data.isEmpty) return [];

        return (data as List)
            .expand((instruction) => instruction['steps'] as List)
            .map((step) => {
                  'step': (step['number'] as int).toString(),
                  'instruction': step['step'] as String,
                })
            .toList();
      } else {
        print("Error Instructions Response Body: ${response.body}");
        throw Exception('Gagal mengambil instruksi.');
      }
    } catch (e) {
      print("Error in fetchInstructions: $e");
      throw Exception('Kesalahan saat mengambil instruksi: $e');
    }
  }
}
