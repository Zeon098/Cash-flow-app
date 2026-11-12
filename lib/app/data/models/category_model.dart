import '../../core/utils/formatters.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.icon = 'category',
    this.color = '#64748B',
  });

  final String id;
  final String name;
  final String type; // 'income' | 'expense'
  final String icon;
  final String color;

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        id: Json.str(j['id']),
        name: Json.str(j['name']),
        type: Json.str(j['type']),
        icon: Json.str(j['icon']),
        color: Json.str(j['color']),
      );
}
