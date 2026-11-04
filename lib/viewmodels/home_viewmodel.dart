import 'package:flutter/material.dart';
import '../data/models/course_model.dart';
import '../data/repositories/course_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final CourseRepository _courseRepository;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isRefreshing = false;

  HomeViewModel(this._courseRepository);

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isRefreshing => _isRefreshing;

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Stream<List<CourseModel>> get coursesStream {
    return _courseRepository.streamCourses(
      category: _selectedCategory,
      searchQuery: _searchQuery,
    );
  }

  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    _isRefreshing = false;
    notifyListeners();
  }
}
