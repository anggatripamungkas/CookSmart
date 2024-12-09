class Recipe {
  final int id;
  late final String title;
  late final String imageUrl;
  final String instructions;
  late final int calories;
  late final String protein;
  late final String carbs;
  late final String fat;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.instructions,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  // Factory constructor untuk membuat instance Recipe dari JSON
  factory Recipe.fromJson(Map<String, dynamic> json) {
    final nutrition = json['nutrition'] ?? {};
    return Recipe(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'No title',
      imageUrl: json['image'] ?? '',
      instructions: json['instructions'] ?? 'No instructions',
      calories: nutrition['calories'] ?? 0,
      protein: nutrition['protein'] ?? '0 g',
      carbs: nutrition['carbs'] ?? '0 g',
      fat: nutrition['fat'] ?? '0 g',
    );
  }

  // Metode untuk memperbarui instruksi
  Recipe withUpdatedInstructions(List<Map<String, String>> instructionsList) {
    final instructionsString = instructionsList
        .map((step) => 'Step ${step['step']}: ${step['instruction']}')  // Membuat format string yang lebih mudah dibaca
        .join('\n'); // Gabungkan langkah-langkah instruksi dengan newline
    return Recipe(
      id: this.id,
      title: this.title,
      imageUrl: this.imageUrl,
      instructions: instructionsString,  // Gunakan instruksi yang sudah berbentuk string
      calories: this.calories,
      protein: this.protein,
      carbs: this.carbs,
      fat: this.fat,
    );
  }

  // Metode untuk membuat salinan baru dari Recipe dengan beberapa properti yang diperbarui
  Recipe copyWith({
    int? calories,
    String? protein,
    String? carbs,
    String? fat,
    String? title,
    String? imageUrl,
    String? instructions,
  }) {
    return Recipe(
      id: this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      instructions: instructions ?? this.instructions,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }
}
