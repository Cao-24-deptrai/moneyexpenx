import 'package:flutter/material.dart';

class CategoryIcons {
  static const Map<String, IconData> iconMap = {
    'work': Icons.work_outline,
    'trending_up': Icons.trending_up,
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'shopping_bag': Icons.shopping_bag,
    'sports_esports': Icons.sports_esports,
    'payment': Icons.payment,
    'school': Icons.school,
    'medical_services': Icons.medical_services,
    'flight': Icons.flight,
    'home': Icons.home,
    'movie': Icons.movie_outlined,
    'fitness_center': Icons.fitness_center,
    'phone': Icons.phone,
    'coffee': Icons.coffee,
  };

  static IconData getIcon(String key) {
    return iconMap[key] ?? Icons.payment;
  }
}
