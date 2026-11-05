import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/error_mapper.dart';

abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  final List<StreamSubscription> _subscriptions = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  Future<T?> runGuarded<T>(Future<T> Function() action, {Function(dynamic)? onError}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await action();
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = ErrorMapper.map(e);
      notifyListeners();
      if (onError != null) {
        onError(e);
      }
      return null;
    }
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
