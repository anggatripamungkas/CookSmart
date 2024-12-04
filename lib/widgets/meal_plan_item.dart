import 'package:flutter/material.dart';
import '../models/meal_plan.dart';

class MealPlanItem extends StatelessWidget {
  final MealPlan mealPlan;

  MealPlanItem({required this.mealPlan});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(mealPlan.day),
        subtitle: Text(mealPlan.meals.join(', ')),
      ),
    );
  }
}
