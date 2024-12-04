class MealPlan {
  final String day;
  final List<String> meals;

  MealPlan({
    required this.day,
    required this.meals,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      day: json['day'] ?? '',  // Menambahkan fallback jika 'day' null
      meals: json['meals'] != null ? List<String>.from(json['meals']) : [], // Fallback jika 'meals' null
    );
  }
}
