import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final int order;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.order,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return CategoryModel(
      id: snapshot.id,
      name: data['name'] ?? 'Category',
      icon: data['icon'] ?? 'folder',
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'order': order,
    };
  }
}
